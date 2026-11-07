//
//  TodayView.swift
//  KmKroner
//

import SwiftUI

/// Placeholder for logging today's commute.
struct TodayView: View {
    var body: some View {
        // Each tab owns its NavigationStack, so each keeps its own
        // navigation history when you switch tabs.
        NavigationStack {
            ContentUnavailableView(
                "Nothing logged today",
                systemImage: "car",
                description: Text("Your trips for today will show here.")
            )
            .navigationTitle("Today")
        }
    }
}

#Preview {
    TodayView()
}
