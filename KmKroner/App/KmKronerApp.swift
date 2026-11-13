//
//  KmKronerApp.swift
//  KmKroner
//
//  Created by Imalka Muthukumara on 2026-11-02.
//

import SwiftData
import SwiftUI

/// App entry point: owns the AppModel and the SwiftData store.
@main
struct KmKronerApp: App {
    @State private var appModel = AppModel()
    /// The opened store, or why it couldn't be opened.
    private let container: Result<ModelContainer, any Error>

    init() {
        container = Result { try ModelSchema.makeContainer() }
    }

    var body: some Scene {
        WindowGroup {
            switch container {
            case .success(let container):
                RootTabView()
                    .environment(appModel)
                    .modelContainer(container)
            case .failure(let error):
                StoreErrorView(error: error)
            }
        }
    }
}
