# Peninsula Todo — Dynamic Island To-Do List

## What This Is

A macOS notch app (forked from [Peninsula](https://github.com/Celve/Peninsula)) that replaces Peninsula's gallery views with a slick to-do list UI. The notch expands on hover revealing a prioritized task list fed by the Superhuman Go AI service — which analyzes user context and auto-creates detailed to-do items. For the hackathon, the UI reads from local storage/mocks instead of the live database.

## Core Value

AI-created tasks from Superhuman Go surface instantly in the macOS notch — no window switching, no app context loss.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Notch expands on hover with Peninsula animation logic intact
- [ ] Todo list displayed inside the expanded notch panel
- [ ] Each item shows: title, priority badge (High/Normal/Low), done checkbox, delete button
- [ ] Checking an item crosses it out (strikethrough), item stays visible
- [ ] Input field at bottom to add new items manually
- [ ] Data persisted in UserDefaults (local storage mock for real DB)
- [ ] UI reuses Peninsula's dark aesthetic (dark background, clean typography)

### Out of Scope

- Real Superhuman Go backend integration — deferred post-hackathon demo
- Jira ticket links — mentioned as nice-to-have, not needed for demo
- Due dates — not needed for v1
- cmd-Tab switcher, notification center, tray, timer — Peninsula features being gutted

## Context

- **Base project**: Fork of [Celve/Peninsula](https://github.com/Celve/Peninsula) — Swift/SwiftUI macOS app
- **Key reuse**: `NotchViewModel` (animation, sizing, hover detection), `NotchView`, `NotchWindow` machinery
- **What gets replaced**: `GalleryModel`/`GalleryItem` content — all the individual gallery views (apps, timer, tray, notification, settings, switching) replaced with a single `TodoView`
- **Hackathon context**: Speed over polish; local UserDefaults storage simulates the real DB that Superhuman Go will write to
- **Future integration**: Superhuman Go agent posts todo items (title + priority + optional Jira links) to a database; this app will eventually poll/subscribe to that instead of UserDefaults

## Constraints

- **Swift/SwiftUI**: Must stay in the existing Peninsula Xcode project — no framework changes
- **Speed**: Hackathon build — 1-2 phases max, no over-engineering
- **macOS only**: No iOS/iPadOS target needed
- **UserDefaults**: Simple persistence for demo; data model must be compatible with future Codable struct from Superhuman Go
- **Xcode project management**: New Swift files must be added to the `.xcodeproj` via `ruby` scripting (xcodeproj gem) or direct `project.pbxproj` editing — files on disk alone won't compile. Plans must include explicit file registration steps.
- **Build toolchain**: App is built and run via `xcodebuild` or Xcode IDE. Plans must include a build verification step (`xcodebuild build` against the Peninsula scheme) to confirm the app compiles after each change.
- **Entitlements & signing**: Peninsula requires Accessibility entitlement; any new code must not break the existing entitlements/signing setup.
- **Dependencies**: Peninsula uses Swift Package Manager (LaunchAtLogin, etc.) — new code must not introduce CocoaPods or Carthage.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Fork Peninsula, gut gallery views | Fastest path to working notch UI — all animation/window logic proven | — Pending |
| Single `todo` gallery item replaces all tabs | No navigation complexity needed for hackathon | — Pending |
| UserDefaults with Codable TodoItem struct | Simple, fast, easy to swap for network layer later | — Pending |

---
*Last updated: 2026-03-17 after adding Xcode build constraints*
