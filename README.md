# KmKroner

An iOS app for people in Denmark who drive to work. Log the days you drove
to each workplace with one tap. At the end of the year you have exactly the
numbers SKAT's TastSelv asks for in the commuting deduction
(*kørselsfradrag*): per home address and workplace, the period, days of
driving per month, km per day (round trip) and toll-bridge crossings.

The app collects and presents the data. **It doesn't calculate the
deduction**: SKAT does that from the numbers you enter.

> **Status: in active development.** The data layer is finished and tested.
> Address search is in progress, and the screens come next. Not on the App
> Store yet.

## Why
Many people in Denmark commute to more than one workplace, for example a
full-time job plus courier shifts. When it's time to fill in TastSelv,
they reconstruct a year of driving from payslips and memory. KmKroner turns
that into a daily habit that takes a few seconds, and lays the result out in
the same order as TastSelv's own steps
([screenshots](docs/tastselv/README.md)).

## Tech
- **SwiftUI** on iOS 18, with no third-party dependencies
- **SwiftData** with a versioned schema (`SchemaV1`), a migration plan, and
  models kept CloudKit-ready for future iCloud sync
- **Observation** (`@Observable`), not `ObservableObject`
- **Swift concurrency:** strict checking set to *complete*, and the main
  actor as the default isolation, so moving to the Swift 6 language mode is
  a small step. Pure logic is marked `nonisolated`.
- **MapKit** for address search and, next, route distance
- **Swift Testing** for unit tests (parameterised, on in-memory stores) and
  **XCTest** for UI tests, run from one test plan with code coverage

## Architecture
MVVM with `@Observable`. Views stay dumb: they read with `@Query` and pass
actions on. All writes go through small store classes, which hold the rules.

```
Views ──@Query (read)──────────────▶ SwiftData
  │                                     ▲
  └─actions─▶ ViewModels ─▶ Services ───┘ (stores: the only writers)
                              │
                              └─ pure logic: DayCalendar, TastSelv grouping
```

| Folder | Contents |
|---|---|
| `Models/` | `Workplace`, `Trip`, `HomeAddress`, nested in `SchemaV1` |
| `Services/` | `TripStore`, `WorkplaceStore`, `HomeStore`, `DayCalendar`, `AddressSearch` |
| `ViewModels/` | `@Observable` presentation state |
| `Views/<Feature>/` | one folder per tab: Today, Calendar, Summary, Settings |
| `PreviewSupport/` | sample data as a `PreviewModifier` (`.sampleData` trait) |

## Design decisions worth a look
- **A "day" is a Copenhagen day.** A `Date` is an instant, not a day.
  [`DayCalendar`](KmKroner/Services/DayCalendar.swift) fixes the calendar to
  Gregorian, Europe/Copenhagen and Monday first. It steps through days with
  calendar arithmetic, never `+ 86_400` seconds, because daylight-saving
  days are 23 or 25 hours long. Tests pin both changeover days and check the
  results don't depend on the device's time zone.
- **Trips keep the km they were logged with.** Correcting a workplace's
  distance doesn't rewrite earlier trips. Changing past trips is an explicit
  action, `WorkplaceStore.applyKm(_:to:from:)`, applied from a chosen date.
- **Uniqueness without unique constraints.** CloudKit doesn't allow
  `@Attribute(.unique)`, so [`TripStore`](KmKroner/Services/TripStore.swift)
  enforces one trip per workplace per day. Logging the same day twice
  changes nothing, because TastSelv counts days, not taps. Undo removes
  exactly the trip it logged instead of using `UndoManager`, which would
  undo whatever changed last.
- **The CloudKit rules are tests, not comments.**
  [`SchemaTests`](KmKronerTests/SchemaTests.swift) reads the SwiftData
  schema and fails if any property lacks a default value, any relationship
  is required, or anything is unique. Another test reopens a store from
  disk through the migration plan.
- **Objective-C delegates under the main-actor default.**
  [`AddressSearch`](KmKroner/Services/AddressSearch.swift) is an
  `@Observable NSObject`. Its MapKit delegate methods are `nonisolated` and
  use `MainActor.assumeIsolated`, because MapKit calls them on the main
  thread. Typing is debounced by cancelling a `Task`, with no Combine.
- **A package I took out again.** The date logic started in a local Swift
  package so its tests could run with `swift test` in seconds. When the
  scope changed from "calculate the deduction" to "provide SKAT's data",
  the package no longer justified its cost: a workspace, `public` on every
  API, and a value-type copy of every model. Moving it into the app target
  was a deliberate trade-off, recorded in the commit history.

## How I work on it
- **Planned as a backlog.** Every change is a ticket with a "Done when"
  checklist: plan, review the plan, build, test, then one commit that
  explains what changed and why.
- **Review-sized changes.** Each ticket is about 250 lines or fewer,
  including its tests, so it can be properly reviewed in one sitting. Tests
  ship with the code they test.
- **Built with an AI coding agent.** I use Claude Code for much of the
  typing. Scope, architecture and the final call on each change are mine,
  and I review every diff before it's committed.
  [`CLAUDE.md`](CLAUDE.md) holds the project's conventions as configuration
  in the repo: architecture rules, concurrency defaults, comment style and
  change size.

## Roadmap
1. ✅ Project setup, test targets
2. ✅ Data model, versioned schema, stores, date utilities
3. 🔄 Workplaces, home address and route distance (MapKit)
4. Day logging: Today screen, calendar, day editor, backfill
5. Grouping trips into TastSelv entries
6. Year summary, step-by-step TastSelv guide, PDF and CSV export
7. Reminders, onboarding, Danish and English localisation, accessibility
8. TestFlight beta and App Store release

## Build and test
Requires Xcode 26 or later and the iOS 18 SDK or newer.

```bash
open KmKroner.xcodeproj
```

Run the tests with ⌘U, or from the command line:

```bash
xcodebuild test -project KmKroner.xcodeproj -scheme KmKroner \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -parallel-testing-enabled NO
```

## Disclaimer
KmKroner isn't affiliated with SKAT and isn't tax advice. Always check
the numbers you enter in TastSelv.
