//
//  CalendarView.swift
//  KmKroner
//

import SwiftUI

/// Placeholder for the month calendar of worked days.
struct CalendarView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No work days yet",
                systemImage: "calendar",
                description: Text("Days you worked will be marked here.")
            )
            .navigationTitle("Calendar")
        }
    }
}

#Preview {
    CalendarView()
}
