//
//  SettingsView.swift
//  KmKroner
//

import SwiftUI
import DeductionEngine

/// Placeholder for settings (home address, workplaces, etc.).
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    LabeledContent("Engine", value: "v\(EngineInfo.version)")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
