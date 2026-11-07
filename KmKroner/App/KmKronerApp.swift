//
//  KmKronerApp.swift
//  KmKroner
//
//  Created by Imalka Muthukumara on 2026-11-02.
//

import SwiftUI

@main
struct KmKronerApp: App {
    // The App struct owns the model. `@State` keeps a single instance alive
    // for the app's lifetime even though `body` may be re-evaluated. With
    // @Observable types, `@State` replaces `@StateObject`.
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                // Passes the model down by type; any view can read it with
                // `@Environment(AppModel.self)`. Replaces `.environmentObject`.
                .environment(appModel)
        }
    }
}
