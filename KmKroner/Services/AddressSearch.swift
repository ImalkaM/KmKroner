//
//  AddressSearch.swift
//  KmKroner
//

import Contacts
import MapKit
import Observation
import SwiftUI

/// One search suggestion, e.g. "Søndergade 1" / "8000 Aarhus C, Danmark".
struct AddressSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    fileprivate let completion: MKLocalSearchCompletion
}

/// Address autocomplete for Danish addresses, on Apple Maps. Needs no location permission.
// NSObject because MKLocalSearchCompleter reports through an Objective-C delegate.
@Observable
final class AddressSearch: NSObject {
    /// What the user typed. Changes reach MapKit 250 ms after typing stops.
    var query = "" {
        didSet { scheduleSearch() }
    }
    private(set) var suggestions: [AddressSuggestion] = []
    /// Set when MapKit fails, e.g. with no network.
    private(set) var error: (any Error)?

    /// Biases results to Denmark, Bornholm included. A bias, not a filter.
    static let denmark = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 56.2, longitude: 11.6),
        span: MKCoordinateSpan(latitudeDelta: 3.6, longitudeDelta: 8.6)
    )

    @ObservationIgnored private let completer = MKLocalSearchCompleter()
    @ObservationIgnored private var pending: Task<Void, Never>?
    private let debounce: Duration

    init(debounce: Duration = .milliseconds(250)) {
        self.debounce = debounce
        super.init()
        completer.resultTypes = .address
        completer.region = Self.denmark
        completer.delegate = self
    }

    /// Looks up the full address and coordinate of a picked suggestion.
    func resolve(_ suggestion: AddressSuggestion) async throws -> PickedAddress {
        let request = MKLocalSearch.Request(completion: suggestion.completion)
        request.resultTypes = .address
        request.region = Self.denmark
        let response = try await MKLocalSearch(request: request).start()
        guard let item = response.mapItems.first else { throw MKError(.placemarkNotFound) }
        return PickedAddress(mapItem: item)
    }

    // Debounce by cancelling the previous wait: only the last keystroke reaches MapKit,
    // which also keeps us under its request throttling.
    private func scheduleSearch() {
        pending?.cancel()
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            completer.cancel()
            suggestions = []
            error = nil
            return
        }
        pending = Task { [weak self, debounce] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            self?.completer.queryFragment = text
        }
    }
}

// The delegate protocol has no actor annotation, so these are nonisolated;
// MapKit calls them on the main thread, which assumeIsolated checks.
extension AddressSearch: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        MainActor.assumeIsolated {
            suggestions = self.completer.results.map {
                AddressSuggestion(title: $0.title, subtitle: $0.subtitle, completion: $0)
            }
            error = nil
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        MainActor.assumeIsolated {
            suggestions = []
            // "No match" isn't a failure; the list is just empty.
            self.error = (error as? MKError)?.code == .placemarkNotFound ? nil : error
        }
    }
}

private extension PickedAddress {
    init(mapItem: MKMapItem) {
        // placemark is deprecated from iOS 26; fine while the app targets iOS 18.
        let placemark = mapItem.placemark
        self.init(
            postalAddress: placemark.postalAddress ?? CNPostalAddress(),
            coordinate: placemark.coordinate,
            fallbackName: mapItem.name ?? ""
        )
    }
}

#if DEBUG
/// Throwaway canvas for trying live search; replaced by AddressSearchView in T2.1b.
private struct AddressSearchPlayground: View {
    @State private var search = AddressSearch()
    @State private var picked: PickedAddress?

    var body: some View {
        List {
            TextField("Address", text: $search.query)
            if let picked {
                Text("\(picked.formattedAddress)\n\(picked.latitude), \(picked.longitude)")
                    .font(.caption)
            }
            if let error = search.error {
                Text(error.localizedDescription).foregroundStyle(.red)
            }
            ForEach(search.suggestions) { suggestion in
                Button {
                    Task { picked = try? await search.resolve(suggestion) }
                } label: {
                    VStack(alignment: .leading) {
                        Text(suggestion.title)
                        Text(suggestion.subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview("Address search") {
    AddressSearchPlayground()
}
#endif
