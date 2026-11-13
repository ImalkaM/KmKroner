//
//  StoreErrorView.swift
//  KmKroner
//

import SwiftUI

/// Shown instead of the app when the saved data can't be opened, e.g. after a
/// failed migration. The data stays untouched on disk, so a fixed update can
/// still open it.
struct StoreErrorView: View {
    let error: any Error

    var body: some View {
        ContentUnavailableView {
            Label("Couldn't open your data", systemImage: "exclamationmark.triangle")
        } description: {
            Text("Your logged trips are still saved on this iPhone. Please update KmKroner, or contact support if this keeps happening.")
        } actions: {
            Text(error.localizedDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    StoreErrorView(error: CocoaError(.fileReadCorruptFile))
}
