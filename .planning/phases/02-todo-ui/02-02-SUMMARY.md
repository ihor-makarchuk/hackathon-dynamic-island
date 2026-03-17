---
phase: 02-todo-ui
plan: 02
subsystem: ui
tags: [swiftui, todo, notch, macos, views]

# Dependency graph
requires:
  - phase: 02-todo-ui-01
    provides: TodoItem model, TodoStore singleton with CRUD and filtering API
  - phase: 01-shell
    provides: NotchCompositeView, NotchViewModel sizing, HeaderView structure
provides:
  - DateCarouselView: horizontal day navigation strip with Today/Yesterday/Tomorrow labels
  - TodoInputView: text field with Enter submission and priority prefix parsing
  - TodoDetailView: expandable panel with link and notes fields per todo item
  - TodoRowView: full row with checkbox, strikethrough, priority badge, hover delete/expand
  - TodoView: main container wiring date carousel, scrollable list, and input field
  - NotchCompositeView updated: TodoView replaces TodoPlaceholderView stub
  - NotchViewModel updated: panel height increased to 501px for full todo list
affects: [02-03, 02-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - SwiftUI dark-aesthetic views using .white.opacity() for secondary elements
    - Priority prefix parsing (! = high, !! = low) in TodoInputView
    - Hover-visible action buttons via .onHover modifier in TodoRowView
    - LazyVStack inside ScrollView for scrollable todo list

key-files:
  created:
    - Peninsula/Todo/DateCarouselView.swift
    - Peninsula/Todo/TodoInputView.swift
    - Peninsula/Todo/TodoDetailView.swift
    - Peninsula/Todo/TodoRowView.swift
    - Peninsula/Todo/TodoView.swift
  modified:
    - Peninsula/Notch/Notch/NotchCompositeView.swift
    - Peninsula/Notch/NotchViewModel.swift

key-decisions:
  - "Hover-visible buttons (delete, expand) reduce visual clutter in compact notch UI"
  - "Priority badge shows colored dot + capitalized label for quick visual scanning"
  - "notchOpenedSize height increased from 201px to 501px to fit date carousel + list + input"
  - "TodoPlaceholderView stub removed entirely — no longer referenced anywhere"

patterns-established:
  - "Dark aesthetic: .white.opacity(0.7) for secondary icons, .white for primary text"
  - "All Todo views use .system(design: .rounded) font family for consistency"
  - "Priority prefix convention: '! title' = high, '!! title' = low, 'title' = normal"

requirements-completed: [TODO-01, TODO-02, TODO-03, TODO-04, TODO-05, TODO-06, INPUT-01, INPUT-02, INPUT-03]

# Metrics
duration: 1min
completed: 2026-03-17
---

# Phase 02 Plan 02: Todo UI Views Summary

**Five SwiftUI views delivering complete todo UI: date navigation, item rows with checkbox/priority/hover actions, expandable detail panel, and input with priority prefix parsing — wired into the expanded notch replacing the placeholder stub**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-17T22:53:08Z
- **Completed:** 2026-03-17T22:54:42Z
- **Tasks:** 2
- **Files modified:** 7 (5 created, 2 modified)

## Accomplishments
- Created 5 SwiftUI view files auto-discovered by Xcode 16 PBXFileSystemSynchronizedRootGroup
- TodoRowView with hover-visible delete and expand buttons, priority badge (colored dot + label), checkbox with strikethrough
- TodoInputView parsing `!` and `!!` prefixes for high and low priority on Enter submission
- TodoDetailView providing inline link and notes editing in an expandable panel
- Replaced TodoPlaceholderView with TodoView in NotchCompositeView; increased notch height to 501px

## Task Commits

Each task was committed atomically:

1. **Task 1: Create todo UI view components** - `20720b9` (feat)
2. **Task 2: Wire TodoView into NotchCompositeView and enlarge notch panel** - `33bba02` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `Peninsula/Todo/DateCarouselView.swift` - Horizontal day navigation with chevron buttons and Today/Yesterday/Tomorrow labels
- `Peninsula/Todo/TodoInputView.swift` - Text field with Enter submission and `!`/`!!` priority prefix parsing
- `Peninsula/Todo/TodoDetailView.swift` - Expandable link and notes fields bound to TodoStore.update()
- `Peninsula/Todo/TodoRowView.swift` - Single todo row: checkbox, title, priority badge, hover-visible delete/expand
- `Peninsula/Todo/TodoView.swift` - Main container: DateCarouselView + ScrollView(LazyVStack) + TodoInputView
- `Peninsula/Notch/Notch/NotchCompositeView.swift` - Replaced TodoPlaceholderView with TodoView(), removed placeholder struct
- `Peninsula/Notch/NotchViewModel.swift` - notchOpenedSize height changed from 200+1 to 500+1

## Decisions Made
- Hover-visible buttons keep the notch UI uncluttered — delete and expand only appear on hover
- Priority badge uses a colored dot + capitalized text label (red=High, gray=Normal, blue=Low)
- Height 501px chosen to fit ~30px date carousel + ~350px scrollable list + ~40px input + 16px spacing

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Complete todo UI is now live in the expanded notch panel
- Users can add, check off, delete, and expand todos; navigate between days via carousel
- Ready for Phase 02-03 (persistence/integration polish) and 02-04 if applicable

---
*Phase: 02-todo-ui*
*Completed: 2026-03-17*
