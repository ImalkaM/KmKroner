//
//  Workplace.swift
//  KmKroner
//

import CoreLocation
import Foundation
import SwiftData

/// Where a workplace's round-trip distance came from.
enum DistanceSource: String, CaseIterable {
    case route, manual, skat
}

/// A toll bridge that SKAT gives a separate bridge deduction for.
enum Bridge: String, CaseIterable {
    case storebaelt, oresund, frederikssund
}

extension SchemaV1 {
    /// A place the user commutes to, e.g. Esmark or Wolt.
    @Model
    final class Workplace {
        var id: UUID = UUID()
        var name: String = ""
        var employer: String?

        var formattedAddress: String = ""
        // CLLocationCoordinate2D isn't Codable, so SwiftData can't store it.
        var latitude: Double = 0
        var longitude: Double = 0

        /// Home → work → home, in km.
        var roundTripKm: Double = 0
        /// Raw storage for `distanceSource`.
        var distanceSourceRaw: String = DistanceSource.manual.rawValue
        var distanceUpdatedAt: Date?
        /// Raw storage for `bridge`; `nil` when the route crosses no toll bridge.
        var bridgeRaw: String?

        /// Whether new trips here start as reimbursed by the employer.
        var defaultReimbursed: Bool = false
        var colorTag: String = "blue"
        /// Set when archived: history stays, but it leaves the Today screen.
        var archivedAt: Date?
        var createdAt: Date = Date.now

        /// Trips logged here. `.nullify` so deleting a workplace never deletes tax history.
        @Relationship(deleteRule: .nullify, inverse: \Trip.workplace)
        var trips: [Trip]? = []

        init(
            name: String,
            employer: String? = nil,
            formattedAddress: String = "",
            latitude: Double = 0,
            longitude: Double = 0,
            roundTripKm: Double,
            distanceSource: DistanceSource = .manual,
            bridge: Bridge? = nil,
            defaultReimbursed: Bool = false,
            colorTag: String = "blue"
        ) {
            self.name = name
            self.employer = employer
            self.formattedAddress = formattedAddress
            self.latitude = latitude
            self.longitude = longitude
            self.roundTripKm = roundTripKm
            self.distanceSourceRaw = distanceSource.rawValue
            self.distanceUpdatedAt = .now
            self.bridgeRaw = bridge?.rawValue
            self.defaultReimbursed = defaultReimbursed
            self.colorTag = colorTag
        }

        /// Typed access to `distanceSourceRaw`; unknown values fall back to `.manual`.
        var distanceSource: DistanceSource {
            get { DistanceSource(rawValue: distanceSourceRaw) ?? .manual }
            set { distanceSourceRaw = newValue.rawValue }
        }

        /// The toll bridge on the route to this workplace, if any.
        var bridge: Bridge? {
            get { bridgeRaw.flatMap(Bridge.init(rawValue:)) }
            set { bridgeRaw = newValue?.rawValue }
        }

        /// `latitude` and `longitude` as one value, for MapKit.
        var coordinate: CLLocationCoordinate2D {
            get { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
            set {
                latitude = newValue.latitude
                longitude = newValue.longitude
            }
        }

        var isArchived: Bool { archivedAt != nil }
    }
}
