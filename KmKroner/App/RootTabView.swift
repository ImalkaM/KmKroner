//
//  RootTabView.swift
//  KmKroner
//

import SwiftUI

/// The app's root: a tab bar with one `NavigationStack` per tab.
struct RootTabView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        // `@Environment` gives a read-only reference. `@Bindable` lets us
        // make a two-way `Binding` ($appModel.selectedTab) to a property of
        // an @Observable object. It's the replacement for `@ObservedObject`'s `$`.
        @Bindable var appModel = appModel

        // iOS 18 `Tab` API: each tab is tagged with a value, and the
        // selection binding is type-safe (AppTab), not an Int tag.
        TabView(selection: $appModel.selectedTab) {
            ForEach(AppTab.allCases) { tab in
                Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                    content(for: tab)
                }
            }
        }
    }

    @ViewBuilder
    private func content(for tab: AppTab) -> some View {
        switch tab {
        case .today: TodayView()
        case .calendar: CalendarView()
        case .summary: SummaryView()
        case .settings: SettingsView()
        }
    }
}

#Preview {
    RootTabView()
        .environment(AppModel())
}
