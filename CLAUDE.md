# Project: Commute Tracker (kørselsfradrag app)

## Goal
Learning SwiftUI while building a Danish commute-tax-deduction (kørselsfradrag)
tracker. The point is to understand the code, not just get working output —
explain non-obvious decisions as you go, especially around SwiftData,
@Observable, and navigation. When there's more than one reasonable way to do
something, briefly say why you picked it.

## What the app does
Tracks which days a user drove to which workplace (multiple jobs, e.g.
Esmark, Wolt courier, Norlax), so at year-end they have exactly the data
SKAT's TastSelv asks for: per home address and workplace, the period, days
of driving per month, km per day (round trip) and toll-bridge crossings.
The app does not calculate the deduction; SKAT does. Built for anyone in
Denmark, not one user.

## Stack
- iOS 18 minimum deployment target
- Swift 5
- SwiftUI (no UIKit unless genuinely necessary — explain why if so)
- SwiftData for persistence (no Core Data, no third-party DB)
- No external dependencies unless there's a strong reason — prefer
  first-party frameworks while learning

## Architecture: MVVM + @Observable
- **Models/** — SwiftData `@Model` classes (`Workplace`, `Trip`, `HomeAddress`).
  CloudKit-ready: every property defaulted or optional, relationships
  optional, no unique constraints. Enums are stored as raw Strings. Models
  live inside `SchemaV1` (type aliases keep the short names); a model change
  means a new schema version plus a stage in `KmKronerMigrationPlan`.
  `ModelSchema.makeContainer` builds every container (app, previews, tests).
- **ViewModels/** — `@Observable` classes (NOT `ObservableObject`/`@Published`
  — use the Observation framework). Hold presentation logic, talk to
  Services, expose state to Views.
- **Views/<Feature>/** — grouped by feature, not by type. Keep views dumb:
  they read state and forward user actions to the ViewModel. No business
  logic or data decisions inside a View body.
- **Services/** — thin layer between ViewModels and SwiftData (e.g. the
  stores), plus pure logic: date utilities (`DayCalendar`) and grouping
  trips into TastSelv entries. Keep the pure logic free of SwiftUI and
  SwiftData and mark it `nonisolated`, so it stays easy to unit-test and
  callable off the main actor. One app target, no local packages.

## Folder structure
```
KmKroner.xcodeproj    → the only project; no workspace
KmKroner/             → app target
  App/                → App entry point, root view
  Models/             → SwiftData @Model classes
  ViewModels/         → @Observable classes
  Views/
    <Feature>/        → one folder per feature (Today/, Calendar/, Summary/, Settings/)
  Services/           → stores, DayCalendar, TastSelv grouping
  Extensions/
  Resources/          → assets, String Catalog, rate tables
  PreviewSupport/     → DEBUG-only SampleData PreviewModifier (`.sampleData` trait)
KmKronerTests/        → app unit tests (Swift Testing)
KmKronerUITests/      → UI tests (XCTest)
KmKroner.xctestplan   → both test bundles, code coverage on
```

## Building and testing
- Open `KmKroner.xcodeproj`.
- ⌘U, or: `xcodebuild test -project KmKroner.xcodeproj -scheme KmKroner
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
  -parallel-testing-enabled NO`
- One suite: add `-only-testing:KmKronerTests/DayCalendarTests`

## Conventions
- Use `@Observable` + `@Bindable`, not `@StateObject`/`@ObservedObject`
- Use `NavigationStack` with `navigationDestination(for:)`, not `NavigationView`
- Use `@Query` in views for reactive SwiftData fetching where it keeps things
  simple; move to a ViewModel-driven fetch if the query logic gets complex
- Prefer small, single-purpose views over large ones
- Commit after each working feature, with a message explaining what and why

## Workflow preferences
- Before implementing a feature, briefly outline the approach (models
  touched, new files, data flow) and let me confirm before writing code
- Build incrementally: one feature at a time (scaffold → model → ViewModel
  → View → wire up → run), not the whole app in one pass
- When reviewing existing code, flag non-idiomatic SwiftUI/SwiftData
  patterns even if not directly asked
