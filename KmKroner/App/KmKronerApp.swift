//
//  KmKronerApp.swift
//  KmKroner
//
//  Created by Imalka Muthukumara on 2026-11-02.
//

import SwiftData
import SwiftUI

/// App entry point: owns the AppModel, the SwiftData store and the stores over it.
@main
struct KmKronerApp: App {
    @State private var appModel = AppModel()
    /// The opened store and its stores, or why it couldn't be opened.
    // Built once here, not in a view: TripStore remembers the last log for Undo.
    private let data: Result<(ModelContainer, AppStores), any Error>

    init() {
        data = Result {
            let container = try ModelSchema.makeContainer()
            return (container, AppStores(container: container))
        }
    }

    var body: some Scene {
        WindowGroup {
            switch data {
            case .success(let (container, stores)):
                RootTabView()
                    .environment(appModel)
                    .stores(stores)
                    .modelContainer(container)
            case .failure(let error):
                StoreErrorView(error: error)
            }
        }
    }
}
