//
//  HomeAddress.swift
//  KmKroner
//

import CoreLocation
import Foundation
import SwiftData

/// Where the user lived during a period; distances are measured from here.
// Dated history so moving house doesn't change earlier trips' km.
// A trip uses the address valid on its date; one record is open at a time.
@Model
final class HomeAddress {
    var id: UUID = UUID()
    /// A short name such as "Home".
    var label: String = ""
    var formattedAddress: String = ""
    var latitude: Double = 0
    var longitude: Double = 0
    /// First day at this address.
    var validFrom: Date = Date.distantPast
    /// First day no longer at this address; `nil` while current.
    var validTo: Date?

    init(
        label: String,
        formattedAddress: String,
        latitude: Double,
        longitude: Double,
        validFrom: Date,
        validTo: Date? = nil
    ) {
        self.label = label
        self.formattedAddress = formattedAddress
        self.latitude = latitude
        self.longitude = longitude
        self.validFrom = validFrom
        self.validTo = validTo
    }

    /// `latitude` and `longitude` as one value, for MapKit.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Whether this is the address the user lives at now.
    var isCurrent: Bool { validTo == nil }
}
