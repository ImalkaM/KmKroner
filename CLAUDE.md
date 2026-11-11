# Project: Commute Tracker (kørselsfradrag app)

## Goal
Learning SwiftUI while building a Danish commute-tax-deduction (kørselsfradrag)
tracker. The point is to understand the code, not just get working output —
explain non-obvious decisions as you go, especially around SwiftData,
@Observable, and navigation. When there's more than one reasonable way to do
something, briefly say why you picked it.

## What the app does
Tracks which days the user worked at which job (multiple jobs, e.g. Esmark,
Wolt courier, Norlax), so the Danish commuting tax deduction can be
calculated at year-end based on km driven per job per day.

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
  optional, no unique constraints. Enums are stored as raw Strings. All
  model types are listed once in `ModelSchema`.
- **ViewModels/** — `@Observable` classes (NOT `ObservableObject`/`@Published`
  — use the Observation framework). Hold presentation logic, talk to
  Services, expose state to Views.
- **Views/<Feature>/** — grouped by feature, not by type. Keep views dumb:
  they read state and forward user actions to the ViewModel. No business
  logic or data decisions inside a View body.
- **Services/** — thin layer between ViewModels and SwiftData/calculations
  (e.g. `TaxCalculationService`). Keeps logic testable and decoupled from
  persistence. Services call into `DeductionEngine` for the actual maths.
- **DeductionEngine** (local Swift package at the repo root) — pure Swift
  tax maths and date utilities (e.g. `DayCalendar`). No SwiftUI, SwiftData
  or UIKit imports, so its tests run on the Mac with `swift test` in
  seconds. Put calculation and date logic here, not in the app's Services/.

## Folder structure
```
KmKroner.xcworkspace  → open this, not KmKroner.xcodeproj (see below)
KmKroner/             → app target
  App/                → App entry point, root view
  Models/             → SwiftData @Model classes
  ViewModels/         → @Observable classes
  Views/
    <Feature>/        → one folder per feature (Today/, Calendar/, Summary/, Settings/)
  Services/           → persistence helpers, thin wrappers over DeductionEngine
  Extensions/
  Resources/          → assets, String Catalog, rate tables
  PreviewSupport/     → DEBUG-only SampleData PreviewModifier (`.sampleData` trait)
KmKronerTests/        → app unit tests (Swift Testing)
KmKronerUITests/      → UI tests (XCTest)
DeductionEngine/      → local package: Sources/ and Tests/ (Swift Testing)
KmKroner.xctestplan   → all three test bundles, code coverage on
```

## Building and testing
- Open `KmKroner.xcworkspace`. A bare `.xcodeproj` doesn't expose the
  package's test targets, so ⌘U would skip the engine tests.
- ⌘U, or: `xcodebuild test -workspace KmKroner.xcworkspace -scheme KmKroner
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
  -parallel-testing-enabled NO`
- Engine only, no simulator: `cd DeductionEngine && swift test`

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
