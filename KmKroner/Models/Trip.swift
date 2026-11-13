//
//  Trip.swift
//  KmKroner
//

import DeductionEngine
import Foundation
import SwiftData

/// Which part of the app logged a trip.
enum CreatedVia: String, CaseIterable {
    case today, calendar, backfill, notification
}

extension SchemaV1 {
    /// One workplace on one day.
    // The store (T1.3) enforces one trip per workplace per day, since unique
    // constraints don't work with CloudKit.
    @Model
    final class Trip {
        var id: UUID = UUID()

        /// Copenhagen midnight at the start of the trip's day.
        // Only changed through setDay(_:) so date and dayKey stay in step.
        private(set) var date: Date = Date.distantPast
        /// The day as "2026-11-09", for exact-day queries.
        private(set) var dayKey: String = ""

        var workplace: Workplace?

        /// The workplace's km when logged (FR-12), so later edits don't change past trips.
        var roundTripKm: Double = 0
        /// Round trips that day, 1–3 (split shifts).
        var tripCount: Int = 1
        /// Reimbursed driving doesn't count towards the deduction.
        var reimbursed: Bool = false
        /// Raw storage for `bridge`, snapshotted from the workplace like the km.
        var bridgeRaw: String?
        /// Toll-bridge crossings that day, reported to SKAT per crossing.
        var bridgePassages: Int = 0
        var note: String?
        /// Raw storage for `createdVia`.
        var createdViaRaw: String = CreatedVia.today.rawValue
        /// Shared by all trips from one backfill, so it can be undone as a group.
        var backfillBatchID: UUID?
        var createdAt: Date = Date.now

        /// Creates a trip on the Copenhagen day `day` falls on, copying km, bridge
        /// and reimbursement from the workplace. Bridge passages default to there
        /// and back for each round trip.
        init(
            day: Date,
            workplace: Workplace,
            tripCount: Int = 1,
            bridgePassages: Int? = nil,
            reimbursed: Bool? = nil,
            note: String? = nil,
            createdVia: CreatedVia = .today,
            backfillBatchID: UUID? = nil
        ) {
            self.workplace = workplace
            self.roundTripKm = workplace.roundTripKm
            self.tripCount = tripCount
            self.bridgeRaw = workplace.bridgeRaw
            self.bridgePassages = bridgePassages ?? (workplace.bridge == nil ? 0 : 2 * tripCount)
            self.reimbursed = reimbursed ?? workplace.defaultReimbursed
            self.note = note
            self.createdViaRaw = createdVia.rawValue
            self.backfillBatchID = backfillBatchID
            setDay(day)
        }

        /// Moves the trip to the Copenhagen day `day` falls on.
        func setDay(_ day: Date) {
            let calendar = DayCalendar.copenhagen
            date = calendar.startOfDay(day)
            dayKey = calendar.dayKey(day)
        }

        /// Typed access to `createdViaRaw`; unknown values fall back to `.today`.
        var createdVia: CreatedVia {
            get { CreatedVia(rawValue: createdViaRaw) ?? .today }
            set { createdViaRaw = newValue.rawValue }
        }

        /// The toll bridge crossed on this trip, if any.
        var bridge: Bridge? {
            get { bridgeRaw.flatMap(Bridge.init(rawValue:)) }
            set { bridgeRaw = newValue?.rawValue }
        }

        /// Total km driven that day: snapshot km × trip count.
        var totalKm: Double { roundTripKm * Double(tripCount) }
    }
}
