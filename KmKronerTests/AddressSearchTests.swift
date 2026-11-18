//
//  AddressSearchTests.swift
//  KmKronerTests
//

import Contacts
import CoreLocation
import Foundation
import Testing
@testable import KmKroner

/// Tests for turning MapKit's postal parts into a `PickedAddress`, and the
/// no-location-permission rule. Live search is checked by hand in the preview.
struct AddressSearchTests {
    /// Postal parts as MapKit would return them.
    struct Parts: Sendable, CustomTestStringConvertible {
        let street: String
        let postcode: String
        let city: String
        let expected: String

        var testDescription: String { expected }
    }

    @Test(arguments: [
        Parts(street: "Søndergade 1", postcode: "8000", city: "Aarhus C", expected: "Søndergade 1, 8000 Aarhus C"),
        Parts(street: "Vestergade", postcode: "5000", city: "Odense C", expected: "Vestergade, 5000 Odense C"),
        Parts(street: "Industrivej 10", postcode: "", city: "Skanderborg", expected: "Industrivej 10, Skanderborg"),
        Parts(street: "", postcode: "3700", city: "Rønne", expected: "3700 Rønne"),
    ])
    func formatsDanishPostalAddress(_ parts: Parts) {
        let postal = CNMutablePostalAddress()
        postal.street = parts.street
        postal.postalCode = parts.postcode
        postal.city = parts.city

        let picked = PickedAddress(postalAddress: postal, coordinate: CLLocationCoordinate2D(latitude: 56.15, longitude: 10.2))

        #expect(picked.formattedAddress == parts.expected)
        #expect(picked.postcode == parts.postcode)
        #expect(picked.city == parts.city)
        #expect(picked.latitude == 56.15 && picked.longitude == 10.2)
    }

    @Test func emptyPartsUseTheFallbackName() {
        let picked = PickedAddress(postalAddress: CNPostalAddress(), coordinate: CLLocationCoordinate2D(), fallbackName: "Esmark")
        #expect(picked.formattedAddress == "Esmark")
    }

    /// Without an NSLocation…UsageDescription key iOS can't show a location
    /// prompt at all, so this keeps the "never ask" rule from regressing.
    @Test func appDeclaresNoLocationUsage() {
        let keys = Bundle.main.infoDictionary?.keys.filter { $0.hasPrefix("NSLocation") } ?? []
        #expect(keys.isEmpty, "Location keys found: \(keys)")
    }
}
