//
//  DayCalendar.swift
//  DeductionEngine
//

import Foundation

/// The single definition of "a day" for KmKroner.
///
/// A `Date` is an instant, not a day: which day it falls on depends on the
/// calendar and time zone you ask. The deduction is counted per Danish day,
/// so every part of the app should use this type instead of
/// `Calendar.current` (which follows the phone's settings and changes when
/// the user travels).
///
/// It's a struct holding a configured `Calendar`, rather than an extension on
/// `Calendar`, so the rules (Gregorian, Europe/Copenhagen, Monday first) are
/// fixed in one place and can't be skipped by accident.
public struct DayCalendar: Sendable {
    /// The calendar the whole app uses.
    public static let copenhagen = DayCalendar()

    public let calendar: Calendar

    /// Internal on purpose: the app must use `DayCalendar.copenhagen`, so no
    /// caller can build a calendar in the phone's (or any other) time zone.
    /// Tests can still reach it through `@testable import`.
    init(timeZone: TimeZone = TimeZone(identifier: "Europe/Copenhagen")!) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.firstWeekday = Weekday.monday.rawValue
        self.calendar = calendar
    }

    /// Local midnight at the start of the day `date` falls on.
    public func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    /// A stable string for the day, e.g. "2026-11-09". Useful for equality
    /// checks and queries ("all trips on this day") without time-of-day noise.
    ///
    /// Built from date components instead of `DateFormatter`, which depends on
    /// locale settings and is relatively expensive to create.
    public func dayKey(_ date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }

    /// The start of the day for a key like "2026-11-09", or `nil` if the key
    /// isn't a real date ("2026-02-30", "2026-13-01", "hello").
    public func date(fromDayKey key: String) -> Date? {
        let fields = key.split(separator: "-", omittingEmptySubsequences: false)
        guard fields.count == 3,
              fields[0].count == 4, fields[1].count == 2, fields[2].count == 2,
              let year = Int(fields[0]), let month = Int(fields[1]), let day = Int(fields[2]),
              let date = calendar.date(from: DateComponents(year: year, month: month, day: day))
        else { return nil }

        // `Calendar` quietly rolls invalid dates over (Feb 30 → Mar 2), so
        // check the result still has the key we were given.
        return dayKey(date) == key ? date : nil
    }

    /// The Danish income year (indkomstår) a date belongs to. It's the
    /// calendar year, but in Copenhagen time: 1 Jan 00:30 in Copenhagen is
    /// still 31 Dec in UTC.
    public func incomeYear(of date: Date) -> Int {
        calendar.component(.year, from: date)
    }

    /// Start-of-day dates for every day in `range` (both ends' days included)
    /// that falls on one of `weekdays`.
    ///
    /// Steps with `calendar.date(byAdding: .day, ...)`, never `+ 86_400`
    /// seconds: on daylight-saving days a Danish day is 23 or 25 hours long,
    /// so adding fixed seconds drifts away from midnight and can skip or
    /// repeat a day.
    public func days(in range: ClosedRange<Date>, weekdays: Set<Weekday>) -> [Date] {
        guard !weekdays.isEmpty else { return [] }

        let first = startOfDay(range.lowerBound)
        let last = startOfDay(range.upperBound)
        var result: [Date] = []
        var offset = 0
        while let day = calendar.date(byAdding: .day, value: offset, to: first), day <= last {
            if weekdays.contains(weekday(of: day)) {
                result.append(day)
            }
            offset += 1
        }
        return result
    }

    /// Whether `date` falls on a day after today. A later time today is not
    /// in the future: trips are logged per day, so today is always loggable.
    ///
    /// `now` is a parameter so tests can pin "today" instead of depending on
    /// the real clock.
    public func isFuture(_ date: Date, now: Date = .now) -> Bool {
        startOfDay(date) > startOfDay(now)
    }

    /// The weekday `date` falls on.
    public func weekday(of date: Date) -> Weekday {
        Weekday(rawValue: calendar.component(.weekday, from: date))!
    }
}

/// Days of the week, using `Calendar`'s numbering (1 = Sunday … 7 = Saturday)
/// so values convert directly. Named cases avoid off-by-one mistakes with the
/// raw numbers.
public enum Weekday: Int, CaseIterable, Sendable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    /// Monday to Friday.
    public static let workdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
}
