---
phase: 02-todo-ui
plan: 04
subsystem: ui
tags: [swift, swiftui, pdfkit, anthropic, claude-haiku, file-drop, uniformtypeidentifiers]

# Dependency graph
requires:
  - phase: 02-todo-ui-01
    provides: TodoItem struct and TodoStore.shared.add() for persisting todos
  - phase: 02-todo-ui-02
    provides: TodoView and NotchView drop targeting infrastructure
provides:
  - File-to-todo AI pipeline via FileTodoService (text extraction + Claude Haiku API + store write)
  - Drop hint overlay in TodoView showing visual feedback when a file is dragged over the expanded notch
  - NotchView dragDetector routing .fileURL drops to FileTodoService
affects: [future network layers, API key management, file processing extensions]

# Tech tracking
tech-stack:
  added: [PDFKit (PDFDocument.string for PDF text extraction), UniformTypeIdentifiers (.fileURL UTType), Anthropic claude-haiku-4-5 API via URLSession]
  patterns: [ProcessInfo.processInfo.environment for secret key injection, NSItemProvider.loadItem for file URL extraction from drag providers, MainActor.run for @Published mutation from async context]

key-files:
  created:
    - Peninsula/Todo/FileTodoService.swift
  modified:
    - Peninsula/Notch/NotchView.swift
    - Peninsula/Todo/TodoView.swift

key-decisions:
  - "FileTodoService reads ANTHROPIC_API_KEY from ProcessInfo.processInfo.environment — never hardcoded, never logged"
  - "Content truncated to 8000 chars before API call to keep Haiku fast and cost-effective"
  - "TodoView secondary onDrop acts as fallback for drops that land on expanded notch content area rather than the dragDetector frame"
  - "Drop hint overlay uses allowsHitTesting(false) so it never blocks interaction with underlying list items"
  - "dueDate set to Calendar.current.startOfDay(for: Date()) so AI-created todos appear in today's carousel slot"

patterns-established:
  - "Async service pattern: fire Task{} from sync call, return early on unsupported inputs, log all errors to console, never crash"
  - "NSItemProvider file URL extraction: loadItem(forTypeIdentifier: public.file-url) → Data → URL(dataRepresentation:relativeTo:nil)"

requirements-completed: [INPUT-03]

# Metrics
duration: 2min
completed: 2026-03-18
---

# Phase 2 Plan 04: File Drop AI Todo Creation Summary

**File-drop-to-AI-todo pipeline using PDFKit text extraction and claude-haiku-4-5 API, with drop hint overlay in expanded notch and dual drop targets for full coverage**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-18T09:09:17Z
- **Completed:** 2026-03-18T09:11:10Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Created FileTodoService — accepts .txt/.md/.pdf file URLs, extracts text via UTF-8 or PDFDocument.string, calls claude-haiku-4-5 via URLSession, parses JSON array response, adds todos to TodoStore
- Updated NotchView dragDetector to route .fileURL drops to FileTodoService via NSItemProvider.loadItem
- Added drop hint overlay to TodoView (ZStack with rounded-rect border, doc.badge.plus icon, "Drop to create todos" text) bound to a secondary onDrop handler for the expanded notch content area

## Task Commits

Each task was committed atomically:

1. **Task 1: Create FileTodoService** - `9a824f5` (feat)
2. **Task 2: Wire drop handling in NotchView and add drop hint overlay in TodoView** - `ad044ff` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `Peninsula/Todo/FileTodoService.swift` — New: async service, text extraction (UTF-8 + PDFKit), Claude API call, TodoStore write on MainActor
- `Peninsula/Notch/NotchView.swift` — Updated: dragDetector onDrop replaced .data with .fileURL routing to FileTodoService; added UniformTypeIdentifiers import
- `Peninsula/Todo/TodoView.swift` — Updated: ZStack body, @State isDropTargeted, drop hint overlay, secondary onDrop routing to FileTodoService

## Decisions Made

- ANTHROPIC_API_KEY read from ProcessInfo.processInfo.environment to comply with org security rules (never hardcoded, never logged)
- Content capped at 8000 chars to keep Haiku latency and token cost minimal for the hackathon demo
- Dual drop targets (dragDetector in NotchView + body in TodoView) provide full coverage: dragDetector catches drags over the collapsed/transitioning notch, TodoView catches drops that land inside the expanded panel content
- allowsHitTesting(false) on overlay so list interaction is never blocked during drag

## Deviations from Plan

None — plan executed exactly as written. The `import UniformTypeIdentifiers` addition was a small supporting detail (Rule 3 category) noted in the plan's own instruction "add if not already present."

## Issues Encountered

None — both tasks compiled cleanly on first attempt.

## User Setup Required

**External API key required.** To use the file-drop AI todo feature:

1. Set `ANTHROPIC_API_KEY` in your environment before launching the app:
   ```
   export ANTHROPIC_API_KEY=<your-key>
   open Peninsula.app
   ```
2. Without the key set, `FileTodoService` silently returns an empty todo list (no crash, console log emitted).

## Next Phase Readiness

- All four plans in Phase 02 (Todo UI) are now complete.
- The hackathon demo feature is fully wired: drag a .txt, .md, or .pdf file onto the notch, the notch expands, drop triggers Claude Haiku API, todos appear in today's list.
- No outstanding blockers.

## Self-Check: PASSED

- Peninsula/Todo/FileTodoService.swift: FOUND
- Peninsula/Notch/NotchView.swift: FOUND
- Peninsula/Todo/TodoView.swift: FOUND
- .planning/phases/02-todo-ui/02-04-SUMMARY.md: FOUND
- Commit 9a824f5 (FileTodoService): FOUND
- Commit ad044ff (NotchView + TodoView): FOUND
- Build: SUCCEEDED

---
*Phase: 02-todo-ui*
*Completed: 2026-03-18*
