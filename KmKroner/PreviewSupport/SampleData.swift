//
//  SampleData.swift
//  KmKroner
//

#if DEBUG
import Foundation
import SwiftData
import SwiftUI

/// Sample workplaces and trips for previews and tests. Use `#Preview(traits: .sampleData)`.
// SwiftUI builds the shared context once and reuses it across previews.
struct SampleData: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        let container = try ModelSchema.inMemoryContainer()
        populate(container.mainContext)
        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content
            .stores(AppStores(container: context))
            .modelContainer(context)
    }

    static let firstDayKey = "2026-10-05"
    static let lastDayKey = "2026-11-10"
    static let tripCount = 33  // 16 Esmark + 16 Wolt + extra Wolt on 9 Nov

    /// Inserts a home, Esmark (Mon/Wed/Fri) and Wolt (Tue/Thu/Sat) with their
    /// trips, including a split shift and a day at both.
    static func populate(_ context: ModelContext) {
        let calendar = DayCalendar.copenhagen

        let home = HomeAddress(
            label: "Home",
            formattedAddress: "Søndergade 1, 8000 Aarhus C",
            latitude: 56.1540, longitude: 10.2080,
            validFrom: calendar.date(fromDayKey: "2025-01-01")!
        )
        let esmark = Workplace(
            name: "Esmark",
            employer: "Esmark A/S",
            formattedAddress: "Industrivej 10, 8660 Skanderborg",
            latitude: 56.0380, longitude: 9.9300,
            roundTripKm: 42.6,
            distanceSource: .route,
            colorTag: "blue"
        )
        let wolt = Workplace(
            name: "Wolt",
            employer: "Wolt Denmark ApS",
            formattedAddress: "Aarhus centrum",
            latitude: 56.1567, longitude: 10.2108,
            roundTripKm: 18,
            distanceSource: .manual,
            colorTag: "teal"
        )
        context.insert(home)
        context.insert(esmark)
        context.insert(wolt)

        let range = calendar.date(fromDayKey: firstDayKey)!...calendar.date(fromDayKey: lastDayKey)!
        for day in calendar.days(in: range, weekdays: [.monday, .wednesday, .friday]) {
            context.insert(Trip(day: day, workplace: esmark, createdVia: .calendar))
        }
        for day in calendar.days(in: range, weekdays: [.tuesday, .thursday, .saturday]) {
            let isSplitShift = calendar.dayKey(day) == "2026-10-08"
            context.insert(Trip(day: day, workplace: wolt, tripCount: isSplitShift ? 2 : 1, createdVia: .today))
        }
        context.insert(Trip(
            day: calendar.date(fromDayKey: "2026-11-09")!,
            workplace: wolt,
            note: "Evening shift after Esmark",
            createdVia: .today
        ))
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    /// Shorthand for `.modifier(SampleData())`.
    @MainActor static var sampleData: Self { .modifier(SampleData()) }
}

/// A plain list for checking the sample data in Xcode's canvas.
private struct SampleTripsList: View {
    @Query(sort: \Trip.date, order: .reverse) private var trips: [Trip]

    var body: some View {
        List(trips) { trip in
            LabeledContent(trip.workplace?.name ?? "No workplace") {
                Text("\(trip.dayKey) · \(trip.totalKm, format: .number) km")
            }
        }
        .navigationTitle("\(trips.count) trips")
    }
}

#Preview("Sample trips", traits: .sampleData) {
    NavigationStack {
        SampleTripsList()
    }
}
#endif
