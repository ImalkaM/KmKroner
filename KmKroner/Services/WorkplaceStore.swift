//
//  WorkplaceStore.swift
//  KmKroner
//

import Foundation
import Observation
import SwiftData

/// Adds, archives, deletes and re-measures workplaces.
@Observable
final class WorkplaceStore {
    enum StoreError: LocalizedError {
        case hasTrips(count: Int)

        var errorDescription: String? {
            switch self {
            case .hasTrips(let count):
                "This workplace has \(count) logged trips. Archive it instead, so the trips stay in your history."
            }
        }
    }

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func add(_ workplace: Workplace) throws {
        context.insert(workplace)
        try context.save()
    }

    /// Saves edits views made directly to a workplace (name, colour, bridge).
    func save() throws {
        try context.save()
    }

    /// Hides the workplace from the Today screen; its trips stay.
    func archive(_ workplace: Workplace) throws {
        workplace.archivedAt = .now
        try context.save()
    }

    func unarchive(_ workplace: Workplace) throws {
        workplace.archivedAt = nil
        try context.save()
    }

    /// Deletes a workplace that has no trips; one with trips must be archived.
    func delete(_ workplace: Workplace) throws {
        let count = workplace.trips?.count ?? 0
        guard count == 0 else { throw StoreError.hasTrips(count: count) }
        context.delete(workplace)
        try context.save()
    }

    /// Sets the workplace's round-trip km and updates the km saved on its
    /// trips from `day` onwards (FR-07). Earlier trips keep their km.
    func applyKm(_ km: Double, to workplace: Workplace, from day: Date) throws {
        let start = DayCalendar.copenhagen.startOfDay(day)
        workplace.roundTripKm = km
        workplace.distanceUpdatedAt = .now
        for trip in workplace.trips ?? [] where trip.date >= start {
            trip.roundTripKm = km
        }
        try context.save()
    }
}
