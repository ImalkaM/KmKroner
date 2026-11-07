//
//  AppModel.swift
//  KmKroner
//

import Observation

/// App-wide UI state shared through the SwiftUI environment.
///
/// It uses `@Observable` (Observation framework) instead of `ObservableObject`:
/// SwiftUI then tracks exactly which properties a view reads, and only
/// re-renders views that read a property that changed. No `@Published` needed.
///
/// No `@MainActor` annotation: the target sets `SWIFT_DEFAULT_ACTOR_ISOLATION
/// = MainActor`, so types in the app are main-actor isolated by default.
@Observable
final class AppModel {
    /// The tab currently shown. Kept here, not in view `@State`, so other
    /// parts of the app (e.g. a notification tap later) can switch tabs.
    var selectedTab: AppTab = .today
}

/// The four top-level tabs. Title and icon live here so the tab bar is
/// defined in one place.
enum AppTab: String, Hashable, CaseIterable, Identifiable {
    case today
    case calendar
    case summary
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .today: "Today"
        case .calendar: "Calendar"
        case .summary: "Summary"
        case .settings: "Settings"
        }
    }

    /// SF Symbol names. Placeholders until matched to the design.
    var systemImage: String {
        switch self {
        case .today: "car"
        case .calendar: "calendar"
        case .summary: "chart.bar"
        case .settings: "gearshape"
        }
    }
}
