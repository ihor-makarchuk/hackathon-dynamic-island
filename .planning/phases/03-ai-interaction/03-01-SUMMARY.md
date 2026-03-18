---
phase: 03-ai-interaction
plan: 01
subsystem: ui
tags: [swift, swiftui, claude-api, drag-drop, animation, UTI, UniformTypeIdentifiers]

# Dependency graph
requires:
  - phase: 02-todo-ui
    provides: FileTodoService with Claude Haiku API integration and dual drop targets
provides:
  - ClaudeTodo top-level struct accessible to all callers
  - FileTodoService.process(fileURL:) returning [ClaudeTodo] for review flow
  - FileTodoService.process(text:) for plain text drag input
  - FileTodoService.refine(originalTodos:instruction:) for chat refinement round
  - Pulsing glow border animation as drop zone visual feedback
  - Both drop targets (NotchView + TodoView) accepting .plainText alongside .fileURL
affects: [03-ai-interaction Plan 02 - chat review UI wiring]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "callClaudeAPIWithMessages(system:user:) shared helper for all Claude API calls"
    - "Drop handler placeholder pattern: log + discard, review flow wiring deferred to Plan 02"
    - "Pulsing glow border via nested strokeBorder layers with blur radii (0, 4, 8) and opacity animation"

key-files:
  created: []
  modified:
    - Peninsula/Todo/FileTodoService.swift
    - Peninsula/Todo/TodoView.swift
    - Peninsula/Notch/NotchView.swift

key-decisions:
  - "ClaudeTodo promoted to top-level struct (not nested in FileTodoService class) for direct access by TodoView"
  - "process(fileURL:) removes internal Task{} wrapper — caller now owns async context"
  - "refine() re-reads ANTHROPIC_API_KEY at call time (not cached) for consistency with existing pattern"
  - "Drop handlers are placeholder stubs in Plan 01; actual review flow state machine wired in Plan 02"
  - "Pulsing glow uses three nested strokeBorder layers at blur 0/4/8 for soft layered glow effect"

patterns-established:
  - "Pulsing glow: three nested RoundedRectangle.strokeBorder with blur radii and opacity easeInOut repeatForever animation"
  - "UTI drop handling: check hasItemConformingToTypeIdentifier before loadItem/loadObject for each type"

requirements-completed: [SC-01, SC-02]

# Metrics
duration: 5min
completed: 2026-03-18
---

# Phase 3 Plan 1: AI Interaction Foundation Summary

**FileTodoService refactored to return [ClaudeTodo] arrays for review; both drop targets accept .plainText UTI; Phase 2 overlay replaced with layered pulsing glow border animation**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-18T10:03:05Z
- **Completed:** 2026-03-18T10:08:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- FileTodoService now exposes 3 public async throwing methods (process(fileURL:), process(text:), refine(originalTodos:instruction:)) all returning [ClaudeTodo] — callers own state mutation, service no longer silently adds to TodoStore
- ClaudeTodo promoted to top-level struct, priority(from:) exposed as internal — both accessible to the upcoming review panel
- Both drop targets (NotchView.dragDetector and TodoView.onDrop) now accept [.fileURL, .plainText] with proper UTType-based conditional loading
- Phase 2 "Drop to create todos" overlay replaced with a three-layer pulsing glow border (blur radii 0/4/8, opacity 0.4-1.0 easeInOut 0.7s repeating)

## Task Commits

Each task was committed atomically:

1. **Task 1: Refactor FileTodoService to return [ClaudeTodo] and add text/refine methods** - `14a26d3` (feat)
2. **Task 2: Add pulsing glow drop zone and .plainText UTI support to both drop targets** - `3da929d` (feat)

## Files Created/Modified

- `Peninsula/Todo/FileTodoService.swift` - Top-level ClaudeTodo struct; three public async/throws methods; shared callClaudeAPIWithMessages helper; priority(from:) now internal
- `Peninsula/Todo/TodoView.swift` - Pulsing glow overlay with glowPulse state; onDrop accepts .fileURL and .plainText; import UniformTypeIdentifiers added
- `Peninsula/Notch/NotchView.swift` - dragDetector.onDrop accepts .fileURL and .plainText; loadObject(ofClass: String.self) for text drops

## Decisions Made

- ClaudeTodo promoted to top-level struct rather than nested type for straightforward access from TodoView in Plan 02
- process(fileURL:) removes the internal Task{} wrapper — the caller (drop handler) now manages the async context, which is the correct separation for a data-returning service
- Drop handlers are stub placeholders logging intent; actual `.loading`/`.review` state machine wiring is deferred to Plan 02 as specified
- refine() reads ANTHROPIC_API_KEY at each invocation, consistent with the existing pattern in callClaudeAPIWithMessages

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

Build errors appeared after Task 1 because the existing NotchView.swift and TodoView.swift still called the old void `process(fileURL:)`. This is expected: Task 2 was designed to update those call sites. No extra fixes were needed — the build succeeded immediately after Task 2 changes.

## User Setup Required

None - no external service configuration required. ANTHROPIC_API_KEY is read from environment at runtime as established in Phase 2.

## Next Phase Readiness

- FileTodoService API surface is complete and ready for Plan 02 to wire up the chat review state machine
- Both drop targets accept text and file drops; Plan 02 will replace the placeholder print logs with `.loading` state transitions and review panel display
- ClaudeTodo and priority(from:) are accessible to TodoView for rendering the review list

---
*Phase: 03-ai-interaction*
*Completed: 2026-03-18*
