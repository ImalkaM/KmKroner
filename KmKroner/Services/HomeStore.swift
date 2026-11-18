//
//  HomeStore.swift
//  KmKroner
//

import Foundation
import Observation
import SwiftData

/// The user's home addresses over time. Exactly one is current.
@Observable
final class HomeStore {
    enum StoreError: LocalizedError {
        case moveBeforeCurrentAddress

        var errorDescription: String? {
            switch self {
            case .moveBeforeCurrentAddress:
                "The move date must be after you started living at your current address."
            }
        }
    }

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// The address the user lives at now, if one is set.
    func current() throws -> HomeAddress? {
        var descriptor = FetchDescriptor<HomeAddress>(predicate: #Predicate { $0.validTo == nil })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// The address the user lived at on the Copenhagen day of `day`.
    func address(on day: Date) throws -> HomeAddress? {
        let start = DayCalendar.copenhagen.startOfDay(day)
        // Filtered in Swift: there are only a handful of addresses, and this
        // avoids optional comparisons in #Predicate.
        return try context.fetch(FetchDescriptor<HomeAddress>()).first {
            $0.validFrom <= start && ($0.validTo.map { start < $0 } ?? true)
        }
    }

    /// Makes `address` current from `day`, closing the previous current
    /// address on that day. Also used for the first address.
    func moveHome(to address: HomeAddress, from day: Date) throws {
        let start = DayCalendar.copenhagen.startOfDay(day)
        if let previous = try current() {
            guard start > previous.validFrom else { throw StoreError.moveBeforeCurrentAddress }
            previous.validTo = start
        }
        address.validFrom = start
        address.validTo = nil
        context.insert(address)
        try context.save()
    }

    /// Saves edits views made directly to an address (label, formatted address).
    func save() throws {
        try context.save()
    }
}
