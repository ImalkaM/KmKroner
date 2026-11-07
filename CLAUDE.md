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
- **Models/** — SwiftData `@Model` classes (e.g. `Job`, `WorkEntry`)
- **ViewModels/** — `@Observable` classes (NOT `ObservableObject`/`@Published`
  — use the Observation framework). Hold presentation logic, talk to
  Services, expose state to Views.
- **Views/<Feature>/** — grouped by feature, not by type. Keep views dumb:
  they read state and forward user actions to the ViewModel. No business
  logic or data decisions inside a View body.
- **Services/** — thin layer between ViewModels and SwiftData/calculations
  (e.g. `TaxCalculationService`). Keeps logic testable and decoupled from
  persistence.

## Folder structure
```
CommuteTracker/
  App/              → App entry point, root view
  Models/           → SwiftData @Model classes
  ViewModels/       → @Observable classes
  Views/
    <Feature>/      → one folder per feature (e.g. WorkLog/, Jobs/, Summary/)
  Services/         → persistence helpers, tax calculation, utilities
  Extensions/
```

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
