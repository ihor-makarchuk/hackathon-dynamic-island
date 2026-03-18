---
phase: 02-todo-ui
plan: "03"
subsystem: notch-counter-badge
tags: [swiftui, notch, badge, combine, reactive]
dependency_graph:
  requires: ["02-02"]
  provides: ["collapsed-notch-counter-badge"]
  affects: ["Peninsula/Notch/NotchView.swift", "Peninsula/Notch/NotchViewModel.swift"]
tech_stack:
  added: []
  patterns: ["Combine forward-publishing from nested ObservableObject", "proportional font sizing from notch height"]
key_files:
  created:
    - Peninsula/Todo/TodoCounterBadge.swift
  modified:
    - Peninsula/Notch/NotchViewModel.swift
    - Peninsula/Notch/NotchViewModel+Events.swift
    - Peninsula/Notch/NotchView.swift
decisions:
  - "Combine subscription (todoStore.objectWillChange) added in setupCancellables() to propagate TodoStore changes through NotchViewModel republish"
  - "todoCounterWidth = deviceNotchRect.height * 0.8 + height/8 for consistent proportional sizing with live icons"
  - "HStack wraps LiveView and TodoCounterBadge so badge sits at rightmost edge of collapsed notch"
metrics:
  duration: "~1min"
  completed: "2026-03-18"
  tasks_completed: 2
  files_changed: 4
---

# Phase 2 Plan 03: Notch Counter Badge Summary

**One-liner:** Collapsed notch now shows today's incomplete todo count as a reactive badge that extends the notch's right side proportionally, disappearing when count is zero.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create TodoCounterBadge view | 8e1837f | Peninsula/Todo/TodoCounterBadge.swift |
| 2 | Wire counter badge into collapsed notch | ce374ad | NotchViewModel.swift, NotchViewModel+Events.swift, NotchView.swift |

## What Was Built

**TodoCounterBadge** (`Peninsula/Todo/TodoCounterBadge.swift`): A SwiftUI view that reads `TodoStore.shared.incompleteCount(for: Date())` reactively. Renders a white semi-transparent number only when `count > 0`. Font size scales to 45% of notch height for visual proportion.

**NotchViewModel changes** (`Peninsula/Notch/NotchViewModel.swift`):
- Added `@ObservedObject var todoStore = TodoStore.shared`
- Added `todoCounterWidth` computed property: returns `deviceNotchRect.height * 0.8 + height/8` when status is not opened and count > 0, else 0
- Updated `abstractSize` to include `todoCounterWidth` — notch background widens on the right to accommodate the badge

**Combine subscription** (`Peninsula/Notch/NotchViewModel+Events.swift`):
- Added `todoStore.objectWillChange.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.objectWillChange.send() }` in `setupCancellables()`
- Required because `@ObservedObject` on a nested `ObservableObject` inside another `ObservableObject` does not automatically propagate change notifications up the chain

**NotchView changes** (`Peninsula/Notch/NotchView.swift`):
- Wrapped `LiveView` and `TodoCounterBadge` in an `HStack(spacing: deviceNotchRect.height / 8)`
- Badge appears at the rightmost edge of collapsed notch, after live activity icons
- Same offset/alignment as before ensures proper right-side positioning

## Decisions Made

1. **Combine forward-publish pattern**: `@ObservedObject` on a nested observable does not chain change notifications, so a manual `objectWillChange.sink` was added. This is the correct SwiftUI/Combine pattern for this scenario.

2. **todoCounterWidth formula**: `height * 0.8 + height/8` gives a width that fits a 1-2 digit number with consistent spacing between it and any live icons.

3. **HStack approach**: Wrapping `LiveView` + `TodoCounterBadge` in an `HStack` maintains the existing `LiveView` alignment and appends the badge as the last right-side element.

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- Peninsula/Todo/TodoCounterBadge.swift: FOUND
- Peninsula/Notch/NotchViewModel.swift: contains `todoCounterWidth` - FOUND
- Peninsula/Notch/NotchViewModel.swift: contains `todoStore.incompleteCount(for: Date())` - FOUND
- Peninsula/Notch/NotchViewModel.swift: contains `size += todoCounterWidth` - FOUND
- Peninsula/Notch/NotchViewModel+Events.swift: contains `todoStore.objectWillChange` - FOUND
- Peninsula/Notch/NotchView.swift: contains `TodoCounterBadge(notchHeight:` - FOUND
- Peninsula/Notch/NotchView.swift: contains `HStack` wrapping LiveView and TodoCounterBadge - FOUND
- xcodebuild BUILD SUCCEEDED
