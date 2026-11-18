//
//  PickedAddress.swift
//  KmKroner
//

import Contacts
import CoreLocation
import Foundation

/// An address the user picked from search, ready to save on a home or workplace.
nonisolated struct PickedAddress: Sendable, Equatable {
    /// Danish postal format, e.g. "Søndergade 1, 8000 Aarhus C".
    var formattedAddress: String
    var postcode: String
    var city: String
    var latitude: Double
    var longitude: Double

    /// Builds the address from the postal parts MapKit returns. `fallbackName`
    /// is used when the parts are empty, e.g. for a place with no street address.
    init(postalAddress: CNPostalAddress, coordinate: CLLocationCoordinate2D, fallbackName: String = "") {
        let street = postalAddress.street.trimmingCharacters(in: .whitespacesAndNewlines)
        postcode = postalAddress.postalCode.trimmingCharacters(in: .whitespaces)
        city = postalAddress.city.trimmingCharacters(in: .whitespaces)
        latitude = coordinate.latitude
        longitude = coordinate.longitude

        // Join only the parts that exist, so a missing postcode never leaves "nil" or a stray comma.
        let town = [postcode, city].filter { !$0.isEmpty }.joined(separator: " ")
        let formatted = [street, town].filter { !$0.isEmpty }.joined(separator: ", ")
        formattedAddress = formatted.isEmpty ? fallbackName : formatted
    }
}
