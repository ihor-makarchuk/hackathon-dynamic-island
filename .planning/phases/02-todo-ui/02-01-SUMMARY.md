---
phase: 02-todo-ui
plan: 01
subsystem: ui
tags: [swift, swiftui, userdefaults, codable, observableobject]

# Dependency graph
requires:
  - phase: 01-shell
    provides: TodoItem.swift stub with id, title, priority, isDone, createdAt fields
provides:
  - TodoItem Codable struct with 8 fields including dueDate, link, notes
  - Priority.sortOrder extension for priority-based sorting
  - TodoStore ObservableObject singleton with CRUD and UserDefaults persistence
  - items(for:) date-filtered sorted query
  - incompleteCount(for:) per-day badge counter
affects:
  - 02-02 (todo list UI view)
  - 02-03 (notch counter badge)
  - 02-04 (detail/add views)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - ObservableObject singleton with static shared instance (matches GalleryModel pattern)
    - UserDefaults + JSONEncoder/Decoder persistence with named key
    - Immediate persistence on every mutation (no batch saves)

key-files:
  created:
    - Peninsula/Todo/TodoStore.swift
  modified:
    - Peninsula/Todo/TodoItem.swift

key-decisions:
  - "sortOrder extension added to Priority in TodoItem.swift (co-located with enum, referenced by TodoStore)"
  - "TodoStore follows GalleryModel.shared singleton pattern for consistency"
  - "items(for:) returns active items sorted by priority then done items at bottom — ready for Plan 02"

patterns-established:
  - "Persistence pattern: encode items to Data via JSONEncoder, store in UserDefaults, load on init"
  - "Date filtering: Calendar.current.isDate(_:inSameDayAs:) for calendar-day comparison"

requirements-completed: [STORE-01, STORE-03]

# Metrics
duration: 1min
completed: 2026-03-17
---

# Phase 2 Plan 01: TodoItem and TodoStore Data Foundation Summary

**Expanded TodoItem Codable struct with dueDate/link/notes fields and UserDefaults-backed TodoStore ObservableObject singleton with immediate CRUD persistence and calendar-day filtering**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-17T22:49:22Z
- **Completed:** 2026-03-17T22:50:42Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- TodoItem struct expanded from 5 to 8 fields (id, title, priority, isDone, createdAt, dueDate, link, notes) with all new fields having sensible defaults
- Priority.sortOrder computed property extension enables priority-based sorting in TodoStore
- TodoStore singleton created with CRUD (add, toggleDone, delete, update), immediate UserDefaults persistence, and calendar-day filtering

## Task Commits

Each task was committed atomically:

1. **Task 1: Expand TodoItem model with dueDate, link, notes fields** - `bcf0afb` (feat)
2. **Task 2: Create TodoStore persistence manager with UserDefaults** - `cd8ebaf` (feat)

**Plan metadata:** `92dee3e` (docs: complete plan)

## Files Created/Modified
- `Peninsula/Todo/TodoItem.swift` - Expanded TodoItem struct (8 fields) + Priority.sortOrder extension
- `Peninsula/Todo/TodoStore.swift` - ObservableObject singleton with full CRUD, UserDefaults persistence, date filtering

## Decisions Made
- sortOrder extension placed at the bottom of TodoItem.swift, co-located with the Priority enum it extends
- TodoStore mirrors the GalleryModel.shared singleton pattern for architectural consistency
- items(for:) sorts active items by sortOrder (high=0, normal=1, low=2) with completed items appended at bottom

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- TodoStore.shared and TodoItem are ready to be consumed by SwiftUI views in Plans 02-03
- TodoStore.items(for:) and incompleteCount(for:) are the primary query APIs for the todo list view and notch badge
- No blockers

---
*Phase: 02-todo-ui*
*Completed: 2026-03-17*

## Self-Check: PASSED

- Peninsula/Todo/TodoItem.swift: FOUND
- Peninsula/Todo/TodoStore.swift: FOUND
- .planning/phases/02-todo-ui/02-01-SUMMARY.md: FOUND
- Commit bcf0afb: FOUND
- Commit cd8ebaf: FOUND
- xcodebuild: BUILD SUCCEEDED
