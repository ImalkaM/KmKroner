//
//  StoreTests.swift
//  KmKronerTests
//

import Foundation
import SwiftData
import Testing
@testable import KmKroner

/// Builds an exact instant from an ISO 8601 string with a UTC offset.
private func instant(_ iso: String) throws -> Date {
    try Date(iso, strategy: .iso8601)
}

/// Counts the context's saves, to check a bulk insert saves once.
@MainActor
private final class SaveCounter {
    private(set) var count = 0
    private var token: (any NSObjectProtocol)?

    init(_ context: ModelContext) {
        // didSave is posted synchronously on the saving (main) thread.
        token = NotificationCenter.default.addObserver(
            forName: ModelContext.didSave, object: context, queue: nil
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.count += 1 }
        }
    }

    func stop() {
        if let token { NotificationCenter.default.removeObserver(token) }
    }
}

/// The T1.3 "Done when" checks for the stores. Fuller cases are T1.5.
@MainActor
struct StoreTests {
    let container: ModelContainer
    let stores: AppStores
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try ModelSchema.inMemoryContainer()
        stores = AppStores(container: container)
    }

    private func makeWorkplace(bridge: Bridge? = nil) throws -> Workplace {
        let workplace = Workplace(name: "Esmark", roundTripKm: 42.6, bridge: bridge)
        try stores.workplaces.add(workplace)
        return workplace
    }

    private func tripCount() throws -> Int {
        try context.fetchCount(FetchDescriptor<Trip>())
    }

    // MARK: TripStore

    @Test func loggingTwiceOnOneDayKeepsOneUnchangedTrip() throws {
        let esmark = try makeWorkplace()
        let morning = try instant("2026-11-09T07:00:00+01:00")
        let evening = try instant("2026-11-09T22:00:00+01:00")

        guard case .created(let trip) = try stores.trips.logTrip(workplace: esmark, on: morning) else {
            Issue.record("First log should create a trip"); return
        }
        guard case .alreadyLogged(let same) = try stores.trips.logTrip(workplace: esmark, on: evening) else {
            Issue.record("Second log should report already logged"); return
        }

        #expect(same === trip)
        #expect(trip.tripCount == 1)
        #expect(try tripCount() == 1)
    }

    @Test func twoWorkplacesOnOneDayAreTwoTrips() throws {
        let esmark = try makeWorkplace()
        let wolt = Workplace(name: "Wolt", roundTripKm: 18)
        try stores.workplaces.add(wolt)
        let day = try instant("2026-11-09T12:00:00+01:00")

        try stores.trips.logTrip(workplace: esmark, on: day)
        try stores.trips.logTrip(workplace: wolt, on: day)

        #expect(try stores.trips.trips(on: "2026-11-09").count == 2)
    }

    @Test func undoRemovesOnlyTheLastLog() throws {
        let esmark = try makeWorkplace()
        try stores.trips.logTrip(workplace: esmark, on: try instant("2026-11-09T12:00:00+01:00"))
        try stores.trips.logTrip(workplace: esmark, on: try instant("2026-11-10T12:00:00+01:00"))

        try stores.trips.undoLastLog()

        #expect(try stores.trips.trips(on: "2026-11-10").isEmpty)
        #expect(try stores.trips.trips(on: "2026-11-09").count == 1)
        #expect(stores.trips.lastLog == nil)
    }

    @Test func undoAfterTheTripWasDeletedDoesNothing() throws {
        let esmark = try makeWorkplace()
        guard case .created(let trip) = try stores.trips.logTrip(workplace: esmark, on: .now) else {
            Issue.record("Expected a new trip"); return
        }
        try stores.trips.delete(trip)

        try stores.trips.undoLastLog()

        #expect(try tripCount() == 0)
    }

    @Test(arguments: [(1, 2), (2, 4), (3, 6), (5, 6)])
    func tripCountKeepsBridgeCrossingsInStep(count: Int, crossings: Int) throws {
        let esmark = try makeWorkplace(bridge: .storebaelt)
        guard case .created(let trip) = try stores.trips.logTrip(workplace: esmark, on: .now) else {
            Issue.record("Expected a new trip"); return
        }

        try stores.trips.setTripCount(count, for: trip)

        #expect(trip.tripCount == min(count, 3))
        #expect(trip.bridgePassages == crossings)
    }

    @Test func tripsInIntervalExcludeTheEndDay() throws {
        let esmark = try makeWorkplace()
        for day in ["2026-10-31", "2026-11-01", "2026-11-30", "2026-12-01"] {
            try stores.trips.logTrip(workplace: esmark, on: DayCalendar.copenhagen.date(fromDayKey: day)!)
        }
        let november = DateInterval(
            start: DayCalendar.copenhagen.date(fromDayKey: "2026-11-01")!,
            end: DayCalendar.copenhagen.date(fromDayKey: "2026-12-01")!
        )

        let keys = try stores.trips.trips(in: november).map(\.dayKey)

        #expect(keys == ["2026-11-01", "2026-11-30"])
    }

    @Test func bulkInsertOf250DatesSavesOnceAndSkipsLoggedDays() throws {
        let esmark = try makeWorkplace()
        let calendar = DayCalendar.copenhagen
        let first = calendar.date(fromDayKey: "2026-01-01")!
        let dates = (0..<250).map { calendar.calendar.date(byAdding: .day, value: $0, to: first)! }
        try stores.trips.logTrip(workplace: esmark, on: dates[10])

        let preview = try stores.trips.previewBulkInsert(workplace: esmark, dates: dates)
        let saves = SaveCounter(context)
        let result = try stores.trips.bulkInsert(workplace: esmark, dates: dates, batchID: UUID())
        saves.stop()

        #expect(result == TripStore.BulkResult(inserted: 249, skipped: 1))
        #expect(preview == result)
        #expect(saves.count == 1)
        #expect(try tripCount() == 250)
    }

    @Test func undoBatchRemovesOnlyThatBatch() throws {
        let esmark = try makeWorkplace()
        let calendar = DayCalendar.copenhagen
        let october = ["2026-10-01", "2026-10-02"].map { calendar.date(fromDayKey: $0)! }
        let november = ["2026-11-02", "2026-11-03"].map { calendar.date(fromDayKey: $0)! }
        let batch = UUID()
        try stores.trips.bulkInsert(workplace: esmark, dates: october, batchID: UUID())
        try stores.trips.bulkInsert(workplace: esmark, dates: november, batchID: batch)

        try stores.trips.undoBatch(batch)

        #expect(try tripCount() == 2)
        #expect(esmark.trips?.count == 2)
    }

    // MARK: WorkplaceStore

    @Test func workplaceWithTripsCannotBeDeleted() throws {
        let esmark = try makeWorkplace()
        try stores.trips.logTrip(workplace: esmark, on: .now)

        #expect(throws: WorkplaceStore.StoreError.self) { try stores.workplaces.delete(esmark) }
        try stores.workplaces.archive(esmark)
        #expect(esmark.isArchived)
    }

    @Test func applyKmChangesTripsFromTheDateOnly() throws {
        let esmark = try makeWorkplace()
        let calendar = DayCalendar.copenhagen
        try stores.trips.logTrip(workplace: esmark, on: calendar.date(fromDayKey: "2026-10-31")!)
        try stores.trips.logTrip(workplace: esmark, on: calendar.date(fromDayKey: "2026-11-01")!)

        try stores.workplaces.applyKm(50, to: esmark, from: calendar.date(fromDayKey: "2026-11-01")!)

        #expect(esmark.roundTripKm == 50)
        #expect(try stores.trips.trips(on: "2026-10-31").first?.roundTripKm == 42.6)
        #expect(try stores.trips.trips(on: "2026-11-01").first?.roundTripKm == 50)
    }

    // MARK: HomeStore

    @Test func movingHomeClosesThePreviousAddress() throws {
        let calendar = DayCalendar.copenhagen
        let aarhus = HomeAddress(label: "Home", formattedAddress: "Aarhus", latitude: 0, longitude: 0, validFrom: .distantPast)
        let odense = HomeAddress(label: "Home", formattedAddress: "Odense", latitude: 0, longitude: 0, validFrom: .distantPast)
        try stores.homes.moveHome(to: aarhus, from: calendar.date(fromDayKey: "2025-01-01")!)
        try stores.homes.moveHome(to: odense, from: calendar.date(fromDayKey: "2026-08-01")!)

        #expect(try stores.homes.current() === odense)
        #expect(try stores.homes.address(on: try instant("2026-07-31T23:59:00+02:00")) === aarhus)
        #expect(try stores.homes.address(on: try instant("2026-08-01T00:00:00+02:00")) === odense)
        #expect(try stores.homes.address(on: try instant("2024-12-31T12:00:00+01:00")) == nil)
    }

    @Test func movingBeforeTheCurrentAddressFails() throws {
        let calendar = DayCalendar.copenhagen
        let aarhus = HomeAddress(label: "Home", formattedAddress: "Aarhus", latitude: 0, longitude: 0, validFrom: .distantPast)
        let odense = HomeAddress(label: "Home", formattedAddress: "Odense", latitude: 0, longitude: 0, validFrom: .distantPast)
        try stores.homes.moveHome(to: aarhus, from: calendar.date(fromDayKey: "2026-01-01")!)

        #expect(throws: HomeStore.StoreError.self) {
            try stores.homes.moveHome(to: odense, from: calendar.date(fromDayKey: "2025-06-01")!)
        }
        #expect(aarhus.isCurrent)
    }
}
