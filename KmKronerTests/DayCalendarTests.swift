//
//  DayCalendarTests.swift
//  KmKronerTests
//

import Foundation
import Testing
@testable import KmKroner

/// Builds an exact instant from an ISO 8601 string with an explicit UTC
/// offset, e.g. "2026-03-29T01:30:00+01:00". Tests use this instead of
/// DayCalendar itself, so they don't use the code under test to check it.
private func instant(_ iso: String) throws -> Date {
    try Date(iso, strategy: .iso8601)
}

/// One daylight-saving changeover day in Copenhagen.
struct DSTDay: Sendable, CustomTestStringConvertible {
    let key: String
    let previousKey: String
    let nextKey: String
    let midnight: String        // local midnight, with that morning's offset
    let beforeChange: String    // a time before the clocks change
    let afterChange: String     // a time after the clocks change
    let hoursLong: Double       // 23 in spring, 25 in autumn

    var testDescription: String { key }

    static let all: [DSTDay] = [
        // Spring forward: 02:00 CET → 03:00 CEST, so the day has 23 hours.
        DSTDay(key: "2026-03-29", previousKey: "2026-03-28", nextKey: "2026-03-30",
               midnight: "2026-03-29T00:00:00+01:00",
               beforeChange: "2026-03-29T01:30:00+01:00", afterChange: "2026-03-29T03:30:00+02:00",
               hoursLong: 23),
        // Fall back: 03:00 CEST → 02:00 CET, so 02:30 happens twice and the day has 25 hours.
        DSTDay(key: "2026-10-25", previousKey: "2026-10-24", nextKey: "2026-10-26",
               midnight: "2026-10-25T00:00:00+02:00",
               beforeChange: "2026-10-25T02:30:00+02:00", afterChange: "2026-10-25T02:30:00+01:00",
               hoursLong: 25),
        DSTDay(key: "2027-03-28", previousKey: "2027-03-27", nextKey: "2027-03-29",
               midnight: "2027-03-28T00:00:00+01:00",
               beforeChange: "2027-03-28T01:30:00+01:00", afterChange: "2027-03-28T03:30:00+02:00",
               hoursLong: 23),
        DSTDay(key: "2027-10-31", previousKey: "2027-10-30", nextKey: "2027-11-01",
               midnight: "2027-10-31T00:00:00+02:00",
               beforeChange: "2027-10-31T02:30:00+02:00", afterChange: "2027-10-31T02:30:00+01:00",
               hoursLong: 25),
    ]
}

struct DayCalendarTests {
    let cal = DayCalendar.copenhagen

    // MARK: Daylight saving

    /// A parameterized test: Swift Testing runs it once per DST day and
    /// reports each run separately.
    @Test(arguments: DSTDay.all)
    func daylightSavingDay(_ day: DSTDay) throws {
        let before = try instant(day.beforeChange)
        let after = try instant(day.afterChange)
        let midnight = try instant(day.midnight)

        // Both sides of the clock change are the same day.
        #expect(cal.dayKey(before) == day.key)
        #expect(cal.dayKey(after) == day.key)

        // Start of day is local midnight, from either side of the change.
        #expect(cal.startOfDay(before) == midnight)
        #expect(cal.startOfDay(after) == midnight)

        // Neighbouring days are exactly one day apart, with nothing skipped or repeated.
        let previous = try #require(cal.calendar.date(byAdding: .day, value: -1, to: midnight))
        let next = try #require(cal.calendar.date(byAdding: .day, value: 1, to: midnight))
        #expect(cal.dayKey(previous) == day.previousKey)
        #expect(cal.dayKey(next) == day.nextKey)

        // The reason `+ 86_400` seconds is wrong: this day isn't 24 hours long.
        #expect(next.timeIntervalSince(midnight) == day.hoursLong * 3600)
    }

    // MARK: Income year

    @Test func newYearsEveAndNewYearLandInDifferentIncomeYears() throws {
        let newYearsEve = try instant("2026-12-31T23:30:00+01:00")
        let newYear = try instant("2027-01-01T00:30:00+01:00")

        #expect(cal.incomeYear(of: newYearsEve) == 2026)
        #expect(cal.incomeYear(of: newYear) == 2027)
    }

    @Test func incomeYearUsesCopenhagenNotUTC() throws {
        // 00:30 on 1 Jan in Copenhagen is still 23:30 on 31 Dec in UTC.
        let newYear = try instant("2026-12-31T23:30:00Z")
        #expect(cal.incomeYear(of: newYear) == 2027)
        #expect(cal.dayKey(newYear) == "2027-01-01")
    }

    // MARK: Day keys

    @Test func dayKeyIsZeroPadded() throws {
        #expect(cal.dayKey(try instant("2026-01-05T12:00:00+01:00")) == "2026-01-05")
    }

    @Test(arguments: ["2026-01-01", "2026-02-28", "2028-02-29", "2026-03-29", "2026-10-25", "2026-12-31"])
    func dayKeyRoundTrips(_ key: String) throws {
        let date = try #require(cal.date(fromDayKey: key))
        #expect(cal.dayKey(date) == key)
        #expect(cal.startOfDay(date) == date)
    }

    @Test(arguments: ["2026-02-30", "2026-02-29", "2026-13-01", "2026-00-10", "2026-1-05", "26-01-05", "2026-01-05-01", "hello", ""])
    func invalidDayKeyReturnsNil(_ key: String) {
        #expect(cal.date(fromDayKey: key) == nil)
    }

    // MARK: Ranges of days

    @Test func workdaysAcrossAutumnDSTWeekend() throws {
        // Fri 23 Oct to Fri 30 Oct 2026, crossing the 25-hour Sunday.
        let range = try instant("2026-10-23T18:00:00+02:00")...instant("2026-10-30T07:00:00+01:00")
        let days = cal.days(in: range, weekdays: Weekday.workdays)

        #expect(days.map(cal.dayKey) == [
            "2026-10-23", "2026-10-26", "2026-10-27", "2026-10-28", "2026-10-29", "2026-10-30",
        ])
        #expect(days.allSatisfy { cal.startOfDay($0) == $0 })
    }

    @Test func everyDayAcrossSpringDSTWeekend() throws {
        let range = try instant("2026-03-27T09:00:00+01:00")...instant("2026-03-31T09:00:00+02:00")
        let days = cal.days(in: range, weekdays: Set(Weekday.allCases))

        #expect(days.map(cal.dayKey) == ["2026-03-27", "2026-03-28", "2026-03-29", "2026-03-30", "2026-03-31"])
    }

    @Test func singleDayRangeAndEmptyWeekdays() throws {
        let monday = try instant("2026-11-09T08:00:00+01:00")

        #expect(cal.days(in: monday...monday, weekdays: [.monday]).map(cal.dayKey) == ["2026-11-09"])
        #expect(cal.days(in: monday...monday, weekdays: [.tuesday]).isEmpty)
        #expect(cal.days(in: monday...monday, weekdays: []).isEmpty)
    }

    @Test func weekdayAndFirstWeekday() throws {
        #expect(cal.weekday(of: try instant("2026-11-09T12:00:00+01:00")) == .monday)
        #expect(cal.weekday(of: try instant("2026-11-08T23:30:00+01:00")) == .sunday)
        #expect(cal.calendar.firstWeekday == Weekday.monday.rawValue)
    }

    // MARK: Independence from the phone's settings

    /// The reason DayCalendar exists: the phone's time zone must not change
    /// which day a trip belongs to. This swaps the process-wide default time
    /// zone (what `TimeZone.current` and `Calendar.current` use) to Auckland,
    /// 12 hours ahead, and checks Copenhagen answers are unchanged.
    ///
    /// Changing global state is normally avoided in parallel tests, but it is
    /// safe here: no correct code in this package reads the default zone, so
    /// the swap can only expose bugs, never cause false failures.
    @Test func ignoresDeviceTimeZone() throws {
        let original = NSTimeZone.default
        NSTimeZone.default = try #require(TimeZone(identifier: "Pacific/Auckland"))
        defer { NSTimeZone.default = original }

        // 23:30 on Mon 9 Nov in Copenhagen is already Tue 10 Nov in Auckland.
        let lateMonday = try instant("2026-11-09T23:30:00+01:00")
        #expect(Calendar.current.component(.day, from: lateMonday) == 10, "precondition: the swap took effect")

        #expect(cal.dayKey(lateMonday) == "2026-11-09")
        #expect(cal.startOfDay(lateMonday) == (try instant("2026-11-09T00:00:00+01:00")))
        #expect(cal.weekday(of: lateMonday) == .monday)
        #expect(cal.incomeYear(of: try instant("2026-12-31T23:30:00+01:00")) == 2026)
        #expect(cal.date(fromDayKey: "2026-11-09") == (try instant("2026-11-09T00:00:00+01:00")))
    }

    @Test func otherTimeZoneGivesDifferentDay() throws {
        // Same instant, different zone, different day. That's why the zone is pinned.
        let lateMonday = try instant("2026-11-09T23:30:00+01:00")
        let utc = DayCalendar(timeZone: .gmt)
        let auckland = DayCalendar(timeZone: try #require(TimeZone(identifier: "Pacific/Auckland")))

        #expect(utc.dayKey(lateMonday) == "2026-11-09")
        #expect(auckland.dayKey(lateMonday) == "2026-11-10")
        #expect(cal.dayKey(lateMonday) == "2026-11-09")
    }

    // MARK: Future days

    @Test func isFutureComparesDaysNotTimes() throws {
        let now = try instant("2026-11-09T12:00:00+01:00")

        #expect(!cal.isFuture(try instant("2026-11-09T23:59:00+01:00"), now: now), "later today is still today")
        #expect(!cal.isFuture(try instant("2026-11-08T12:00:00+01:00"), now: now))
        #expect(cal.isFuture(try instant("2026-11-10T00:00:30+01:00"), now: now))
    }
}
