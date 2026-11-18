//
//  SettingsView.swift
//  KmKroner
//

import SwiftUI

/// Placeholder for settings (home address, workplaces, etc.).
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    LabeledContent("Version", value: Bundle.main.appVersion)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

private extension Bundle {
    /// The app's marketing version, e.g. "1.0".
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
    }
}

#Preview {
    SettingsView()
}
