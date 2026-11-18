//
//  AppStores.swift
//  KmKroner
//

import SwiftData
import SwiftUI

/// The three stores, built once from a container and shared through the environment.
struct AppStores {
    let trips: TripStore
    let workplaces: WorkplaceStore
    let homes: HomeStore

    /// Every store uses the container's main context, the same one `@Query` reads,
    /// so a write shows up in views immediately.
    init(container: ModelContainer) {
        let context = container.mainContext
        trips = TripStore(context: context)
        workplaces = WorkplaceStore(context: context)
        homes = HomeStore(context: context)
    }
}

extension View {
    /// Puts each store in the environment, read with `@Environment(TripStore.self)` etc.
    func stores(_ stores: AppStores) -> some View {
        environment(stores.trips)
            .environment(stores.workplaces)
            .environment(stores.homes)
    }
}
