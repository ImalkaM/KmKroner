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

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(appModel)
        }
        .modelContainer(for: ModelSchema.models)
    }
}
