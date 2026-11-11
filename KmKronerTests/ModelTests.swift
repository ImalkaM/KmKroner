//
//  ModelTests.swift
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

/// Tests for the SwiftData models, each on a fresh in-memory store.
// Swift Testing runs init per test, so each test gets a fresh store.
@MainActor
struct ModelTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try ModelSchema.inMemoryContainer()
    }

    /// Inserts a 42.6 km, non-reimbursed Esmark workplace.
    private func makeEsmark() -> Workplace {
        let esmark = Workplace(name: "Esmark", roundTripKm: 42.6, defaultReimbursed: false)
        context.insert(esmark)
        return esmark
    }

    // MARK: Trip days

    @Test func tripStoresCopenhagenMidnightAndDayKey() throws {
        let trip = Trip(day: try instant("2026-11-09T23:30:00+01:00"), workplace: makeEsmark())

        #expect(trip.dayKey == "2026-11-09")
        #expect(trip.date == (try instant("2026-11-09T00:00:00+01:00")))
    }

    @Test func tripDayFollowsCopenhagenNotUTC() throws {
        let trip = Trip(day: try instant("2026-11-09T23:30:00Z"), workplace: makeEsmark())
        #expect(trip.dayKey == "2026-11-10")
    }

    @Test func setDayKeepsDateAndKeyInStep() throws {
        let trip = Trip(day: try instant("2026-11-09T08:00:00+01:00"), workplace: makeEsmark())
        trip.setDay(try instant("2026-10-25T14:00:00+01:00"))

        #expect(trip.dayKey == "2026-10-25")
        #expect(trip.date == (try instant("2026-10-25T00:00:00+02:00")))
    }

    // MARK: Snapshots and defaults

    @Test func tripSnapshotsKmWhenLogged() throws {
        let esmark = makeEsmark()
        let trip = Trip(day: try instant("2026-11-09T08:00:00+01:00"), workplace: esmark)
        try context.save()

        esmark.roundTripKm = 50

        #expect(trip.roundTripKm == 42.6, "FR-12: correcting the workplace doesn't rewrite history")
    }

    @Test func reimbursedDefaultsFromWorkplaceButCanBeOverridden() throws {
        let wolt = Workplace(name: "Wolt", roundTripKm: 18, defaultReimbursed: true)
        context.insert(wolt)
        let day = try instant("2026-11-09T08:00:00+01:00")

        #expect(Trip(day: day, workplace: wolt).reimbursed)
        #expect(!Trip(day: day, workplace: wolt, reimbursed: false).reimbursed)
    }

    @Test func totalKmMultipliesByTripCount() throws {
        let trip = Trip(day: try instant("2026-11-09T08:00:00+01:00"), workplace: makeEsmark(), tripCount: 2)
        #expect(trip.totalKm == 85.2)
    }

    // MARK: Bridges

    @Test func noBridgeMeansNoPassages() throws {
        let trip = Trip(day: try instant("2026-11-09T08:00:00+01:00"), workplace: makeEsmark(), tripCount: 2)
        #expect(trip.bridge == nil)
        #expect(trip.bridgePassages == 0)
    }

    @Test func bridgePassagesDefaultToThereAndBackPerTrip() throws {
        let odense = Workplace(name: "Odense", roundTripKm: 180, bridge: .storebaelt)
        context.insert(odense)
        let day = try instant("2026-11-09T08:00:00+01:00")

        #expect(Trip(day: day, workplace: odense).bridgePassages == 2)
        #expect(Trip(day: day, workplace: odense, tripCount: 2).bridgePassages == 4)
        #expect(Trip(day: day, workplace: odense, bridgePassages: 0).bridgePassages == 0, "e.g. a carpool passenger")
    }

    @Test func tripSnapshotsBridge() throws {
        let odense = Workplace(name: "Odense", roundTripKm: 180, bridge: .storebaelt)
        context.insert(odense)
        let trip = Trip(day: try instant("2026-11-09T08:00:00+01:00"), workplace: odense)

        odense.bridge = nil

        #expect(trip.bridge == .storebaelt)
        #expect(trip.bridgeRaw == "storebaelt")
    }

    // MARK: Enums stored as Strings

    @Test func enumsRoundTripThroughRawStrings() throws {
        let esmark = makeEsmark()
        esmark.distanceSource = .route
        #expect(esmark.distanceSourceRaw == "route")

        let trip = Trip(day: .now, workplace: esmark, createdVia: .backfill)
        #expect(trip.createdViaRaw == "backfill")
        #expect(trip.createdVia == .backfill)
    }

    @Test func unknownRawValueFallsBackInsteadOfCrashing() {
        let esmark = makeEsmark()
        esmark.distanceSourceRaw = "satellite"
        #expect(esmark.distanceSource == .manual)
    }

    // MARK: Relationships and fetching

    @Test func settingTripWorkplaceFillsInverse() throws {
        let esmark = makeEsmark()
        let trip = Trip(day: try instant("2026-11-09T08:00:00+01:00"), workplace: esmark)
        context.insert(trip)
        try context.save()

        #expect(esmark.trips?.map(\.id) == [trip.id])
    }

    @Test func deletingWorkplaceKeepsTripsWithNoWorkplace() throws {
        let esmark = makeEsmark()
        context.insert(Trip(day: try instant("2026-11-09T08:00:00+01:00"), workplace: esmark))
        try context.save()

        context.delete(esmark)
        try context.save()

        let trips = try context.fetch(FetchDescriptor<Trip>())
        #expect(trips.count == 1, ".nullify keeps the tax history")
        #expect(trips.first?.workplace == nil)
        #expect(trips.first?.roundTripKm == 42.6, "the snapshot survives too")
    }

    @Test func fetchByDayKey() throws {
        let esmark = makeEsmark()
        let wolt = Workplace(name: "Wolt", roundTripKm: 18)
        context.insert(wolt)
        context.insert(Trip(day: try instant("2026-11-09T08:00:00+01:00"), workplace: esmark))
        context.insert(Trip(day: try instant("2026-11-09T19:00:00+01:00"), workplace: wolt))
        context.insert(Trip(day: try instant("2026-11-10T08:00:00+01:00"), workplace: esmark))
        try context.save()

        let key = "2026-11-09"
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate { $0.dayKey == key })
        let names = try context.fetch(descriptor).compactMap(\.workplace?.name).sorted()

        #expect(names == ["Esmark", "Wolt"], "FR-09: two workplaces on one day are two trips")
    }

    // MARK: Sample data

    @Test func sampleDataHasExpectedShape() throws {
        SampleData.populate(context)
        try context.save()

        let workplaces = try context.fetch(FetchDescriptor<Workplace>())
        let trips = try context.fetch(FetchDescriptor<Trip>())
        #expect(workplaces.count == 2)
        #expect(trips.count == SampleData.tripCount)
        #expect(try context.fetchCount(FetchDescriptor<HomeAddress>()) == 1)

        let keys = trips.map(\.dayKey)
        #expect(keys.min() == SampleData.firstDayKey)
        #expect(keys.max() == SampleData.lastDayKey)
        #expect(keys.filter { $0 == "2026-11-09" }.count == 2, "the shared day")
        #expect(trips.contains { $0.tripCount == 2 }, "the split shift")
    }
}
