---
phase: 03-ai-interaction
plan: 02
subsystem: ui
tags: [swiftui, drop, claude, notification, animation]

# Dependency graph
requires:
  - phase: 03-ai-interaction-01
    provides: FileTodoService with process(fileURL:)/process(text:)/refine()/priority(from:) and ClaudeTodo struct

provides:
  - DropReviewState enum (idle/loading/review/refining) driving TodoView content regions
  - Loading indicator with "Creating todos..." / "Refining..." text
  - Chat review panel with extracted todo list, priority color dots, refinement input, "Add all" and "Dismiss" buttons
  - Notification bridge from NotchView dragDetector to TodoView via .notchDidReceiveDrop
  - One-round refinement flow via FileTodoService.refine()

affects: [any phase modifying TodoView, NotchView, or drop handling]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - NotificationCenter bridge between NotchView and TodoView for drop event routing
    - State machine enum (DropReviewState) driving mutually exclusive SwiftUI content regions
    - hasRefined guard prevents multiple refinement rounds per review session

key-files:
  created: []
  modified:
    - Peninsula/Todo/TodoView.swift
    - Peninsula/Notch/NotchView.swift

key-decisions:
  - "Tasks 1 and 2 combined into single TodoView.swift rewrite — both tasks modify the same file, splitting would create intermediate invalid state"
  - "DropReviewState Equatable uses title-based comparison for [ClaudeTodo] since ClaudeTodo is Decodable-only (no Equatable)"
  - "hasRefined flag limits refinement to one round per session — matches plan spec and prevents runaway API calls"
  - "Notification bridge (.notchDidReceiveDrop) decouples NotchView drop events from TodoView state without introducing shared mutable state"

patterns-established:
  - "State machine enum pattern: define enum with associated values, switch on it in body to show mutually exclusive content regions"
  - "NotificationCenter bridge pattern: post from dragDetector (collapsed notch), observe in TodoView (expanded notch content)"

requirements-completed: [SC-02, SC-03]

# Metrics
duration: 4min
completed: 2026-03-18
---

# Phase 3 Plan 02: Drop Review Panel Summary

**Four-state DropReviewState machine in TodoView with chat review panel, loading indicator, refinement input, and NotchView notification bridge for the full drag-to-todos demo flow**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-18T10:07:50Z
- **Completed:** 2026-03-18T10:11:30Z
- **Tasks:** 2 (implemented together as single file rewrite)
- **Files modified:** 2

## Accomplishments

- DropReviewState enum (idle/loading/review/refining) with Equatable conformance drives mutually exclusive content regions in TodoView
- Loading indicator shows "Creating todos..." during FileTodoService.process() API call and "Refining..." during FileTodoService.refine() call
- Chat review panel displays extracted ClaudeTodo items with priority color dots (red/gray/blue), refinement TextField, and "Add all" / "Dismiss" action buttons
- "Add all" commits todos to TodoStore with correct dueDate (startOfDay) and priority mapping via FileTodoService.priority(from:)
- NotchView dragDetector posts .notchDidReceiveDrop notifications; TodoView observes them to trigger the review flow from the collapsed notch
- One-round refinement guard (hasRefined) prevents multiple API calls per review session

## Task Commits

Each task was committed atomically:

1. **Task 1 + Task 2: DropReviewState enum, drop handlers, and review panel UI** - `aa8623a` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `Peninsula/Todo/TodoView.swift` - Full rewrite: DropReviewState enum, state property, drop handlers wired to FileTodoService, body switching on review state, reviewPanel() method with scrollable todo list + refinement input + action buttons, reviewPriorityColor() helper
- `Peninsula/Notch/NotchView.swift` - Added Notification.Name.notchDidReceiveDrop extension; updated dragDetector onDrop to post notifications instead of placeholder prints

## Decisions Made

- Tasks 1 and 2 combined into single TodoView.swift rewrite because both tasks modify the same file and splitting would create an intermediate compilation error (reviewPanel not defined yet when body references it).
- DropReviewState Equatable conformance uses title-array comparison for `.review([ClaudeTodo])` since ClaudeTodo only conforms to Decodable, not Equatable.
- One refinement round enforced by `hasRefined` flag — aligns with plan spec; prevents cost accumulation if user spam-submits.
- Notification bridge chosen over dependency injection to keep NotchView and TodoView decoupled; NotchView doesn't need to know TodoView's state type.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. ANTHROPIC_API_KEY already handled in Plan 01 via ProcessInfo.processInfo.environment.

## Next Phase Readiness

- The full drop-to-review demo flow is complete: drag content over notch -> glow -> notch opens -> "Creating todos..." -> Claude presents extracted items -> user reviews -> "Add all"
- One refinement round works end-to-end
- Phase 03 is fully complete — all AI-interaction plans done
- No blockers

---
*Phase: 03-ai-interaction*
*Completed: 2026-03-18*
