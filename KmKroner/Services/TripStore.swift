//
//  TripStore.swift
//  KmKroner
//

import Foundation
import Observation
import SwiftData

/// The only place trips are inserted, changed in ways with rules, or deleted.
/// Views read trips with `@Query` and write through this store.
// @Observable so it can go in the environment and the Undo toast can read lastLog.
@Observable
final class TripStore {
    /// What `logTrip` did.
    enum LogResult {
        case created(Trip)
        /// The workplace already had a trip that day; it was left unchanged.
        case alreadyLogged(Trip)
    }

    /// What `bulkInsert` did, or would do for `previewBulkInsert`.
    struct BulkResult: Equatable {
        var inserted: Int
        /// Days skipped because that workplace already had a trip.
        var skipped: Int
    }

    private let context: ModelContext

    /// The trip the last `logTrip` created, for Undo. Cleared by `undoLastLog`.
    private(set) var lastLog: Trip?

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: Logging

    /// Logs one trip to `workplace` on the Copenhagen day of `day`. A second
    /// log for the same day does nothing: TastSelv counts days, not taps.
    @discardableResult
    func logTrip(workplace: Workplace, on day: Date, createdVia: CreatedVia = .today) throws -> LogResult {
        if let existing = try trip(for: workplace, dayKey: DayCalendar.copenhagen.dayKey(day)) {
            return .alreadyLogged(existing)
        }
        let trip = Trip(day: day, workplace: workplace, createdVia: createdVia)
        context.insert(trip)
        try context.save()
        lastLog = trip
        return .created(trip)
    }

    /// Removes the trip the last `logTrip` created, if it still exists.
    func undoLastLog() throws {
        guard let trip = lastLog else { return }
        lastLog = nil
        // Already deleted elsewhere (e.g. the day editor) means nothing to undo.
        guard trip.modelContext != nil, !trip.isDeleted else { return }
        context.delete(trip)
        try context.save()
    }

    // MARK: Reading

    /// Trips from the start of `interval` up to, not including, its end, oldest first.
    func trips(in interval: DateInterval) throws -> [Trip] {
        let start = interval.start, end = interval.end
        let descriptor = FetchDescriptor<Trip>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date)]
        )
        return try context.fetch(descriptor)
    }

    /// All trips on the day `dayKey` ("2026-11-09").
    func trips(on dayKey: String) throws -> [Trip] {
        let descriptor = FetchDescriptor<Trip>(
            predicate: #Predicate { $0.dayKey == dayKey },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: Editing

    /// Sets the round trips that day (1–3) and resets bridge crossings to
    /// there and back for each, so the two can't drift apart.
    func setTripCount(_ count: Int, for trip: Trip) throws {
        trip.tripCount = min(max(count, 1), 3)
        trip.bridgePassages = trip.bridge == nil ? 0 : 2 * trip.tripCount
        try context.save()
    }

    /// Saves edits views made directly to a trip's properties (km, note, reimbursed).
    func save() throws {
        try context.save()
    }

    func delete(_ trip: Trip) throws {
        context.delete(trip)
        try context.save()
    }

    // MARK: Backfill

    /// How many of `dates` `bulkInsert` would add and skip, without changing anything.
    func previewBulkInsert(workplace: Workplace, dates: [Date]) throws -> BulkResult {
        let (newDays, skipped) = try split(dates, for: workplace)
        return BulkResult(inserted: newDays.count, skipped: skipped)
    }

    /// Logs `workplace` on each of `dates`, skipping days it already has, in
    /// a single save. All new trips share `batchID` so `undoBatch` can remove them.
    @discardableResult
    func bulkInsert(workplace: Workplace, dates: [Date], batchID: UUID) throws -> BulkResult {
        let (newDays, skipped) = try split(dates, for: workplace)
        for day in newDays {
            context.insert(Trip(day: day, workplace: workplace, createdVia: .backfill, backfillBatchID: batchID))
        }
        try context.save()
        return BulkResult(inserted: newDays.count, skipped: skipped)
    }

    /// Deletes every trip from one backfill, in a single save.
    func undoBatch(_ batchID: UUID) throws {
        // Optional comparison: backfillBatchID is nil for trips logged one by one.
        let id: UUID? = batchID
        // Fetch and delete each, not delete(model:where:): a batch delete skips
        // the loaded objects, so workplace.trips could still list them.
        let trips = try context.fetch(FetchDescriptor<Trip>(predicate: #Predicate { $0.backfillBatchID == id }))
        for trip in trips { context.delete(trip) }
        try context.save()
    }

    // MARK: Helpers

    /// That workplace's trip on `dayKey`, if any.
    private func trip(for workplace: Workplace, dayKey: String) throws -> Trip? {
        let workplaceID: UUID? = workplace.id
        var descriptor = FetchDescriptor<Trip>(
            predicate: #Predicate { $0.dayKey == dayKey && $0.workplace?.id == workplaceID }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Splits `dates` into one date per new day and a count of days already
    /// logged for `workplace` (or repeated in `dates`).
    private func split(_ dates: [Date], for workplace: Workplace) throws -> (newDays: [Date], skipped: Int) {
        let calendar = DayCalendar.copenhagen
        // The workplace's existing days, read once rather than queried per date.
        var seen = Set((workplace.trips ?? []).map(\.dayKey))
        var newDays: [Date] = []
        for date in dates where seen.insert(calendar.dayKey(date)).inserted {
            newDays.append(date)
        }
        return (newDays, dates.count - newDays.count)
    }
}
