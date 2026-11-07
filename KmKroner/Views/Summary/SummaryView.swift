//
//  SummaryView.swift
//  KmKroner
//

import SwiftUI

/// Placeholder for the yearly kørselsfradrag summary.
struct SummaryView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No deduction yet",
                systemImage: "chart.bar",
                description: Text("Your yearly kørselsfradrag will be calculated here.")
            )
            .navigationTitle("Summary")
        }
    }
}

#Preview {
    SummaryView()
}
