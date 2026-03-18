# Phase 3: AI Interaction - Context

**Gathered:** 2026-03-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Two AI-powered features layered on top of the existing todo UI:

1. **Enhanced drop + chat review** — Text selection drag (in addition to files) triggers an animated pulsing-border drop zone; dropped content is processed by Claude and displayed as a chat-style review panel inside the notch where the user confirms or dismisses extracted todos before they're added.

2. **"Execute with AI" agent** — Each todo row gets an "Execute with AI" button (hover-visible); clicking it invokes a Claude agent that creates a macOS calendar event using the todo's title, notes, and link fields, then marks the todo done and shows a success toast.

Backend integration with Superhuman Go, multi-agent routing, and non-calendar task execution are explicitly out of scope.

</domain>

<decisions>
## Implementation Decisions

### Drop Zone Animation
- **Animation style**: Pulsing glow border — the notch border glows and pulses while content is being dragged over it
- **No label/icon overlay** — border animation only, no "Drop to create todos" label
- **Auto-expand on drag hover**: Notch opens automatically when content (text or file) is dragged near it — same behavior already implemented for files, extended to text drag
- Existing drop hint overlay (thin border + "Drop to create todos" text from Phase 2) is replaced by the new pulsing glow

### Text Drag Support
- **Drag selected text from any app** (browser, Notes, TextEdit, etc.) works identically to dropping a file
- Implemented via `.plainText` UTI type in addition to `.fileURL` in `onDrop` and `dragDetector`
- Text content is passed directly to `FileTodoService` (or its successor) for Claude processing — same pipeline as files

### Chat Review Interface
- After drop: notch enters **loading state** — animated thinking indicator (pulsing dots or spinner) with "Creating todos..." text replaces the normal todo list while the Claude API call is in progress
- After API response: **chat panel appears inside the notch** — Claude's message shows the extracted todo titles; two action buttons: **"Add all"** and **"Dismiss"**
- User may type a refinement (e.g. "make #2 high priority") — ONE round of free-text refinement is supported; Claude re-processes and shows updated list
- After "Add all": todos are added to today's list, chat panel disappears, normal todo list returns
- After "Dismiss": no todos added, normal todo list returns
- **This replaces the Phase 2 "silent add" behavior** — todos are never silently added; they always go through the review panel

### "Execute with AI" Button
- Button lives on `TodoRowView` hover — visible on hover alongside existing delete/expand buttons (consistent with established pattern)
- **Icon**: lightning bolt (`bolt.fill`) to indicate agent execution
- Claude's discretion on exact placement within the hover row

### Agent Execution (Calendar)
- **Target**: macOS EventKit (local Calendar.app integration — no OAuth, no external API)
- **Input data**: Claude agent receives `title`, `notes`, and `link` from the `TodoItem`
- **Date inference**: Claude extracts date/time hints from title and notes (e.g. "meeting tomorrow 3pm" → tomorrow at 15:00); falls back to today + 1 hour if no date hint found
- **Event fields**: event title = todo title; notes field = todo notes; URL field = todo link (if present)
- **Requires**: `NSCalendarsUsageDescription` entitlement + EventKit permission prompt at first use
- **After success**: todo is auto-checked (marked done) + brief "Calendar event created" toast near the notch
- **Error handling**: if EventKit permission denied or creation fails, show an error toast; Claude's discretion on exact messaging

### Claude's Discretion
- Exact pulsing glow animation parameters (timing, color, blur radius)
- Loading state visual (dots vs spinner, exact text)
- "Execute" button exact placement within hover row
- Toast appearance and dismiss timing
- Error toast messaging

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project constraints & patterns
- `.planning/PROJECT.md` — Peninsula aesthetic, Swift/SwiftUI constraints, Xcode file registration, build verification, no CocoaPods/Carthage, entitlements must not break
- `.planning/REQUIREMENTS.md` — All existing v1 requirements (must not regress); v2 agent requirements now being addressed

### Existing phase context
- `.planning/phases/02-todo-ui/02-CONTEXT.md` — Phase 2 decisions: FileTodoService API pattern, TodoItem fields (title, priority, isDone, dueDate, link, notes), TodoRowView hover pattern, drop UTI types used, ANTHROPIC_API_KEY env var approach

### Key source files (read before planning)
- `Peninsula/Todo/FileTodoService.swift` — Existing Claude Haiku integration; Phase 3 replaces silent-add with chat review panel
- `Peninsula/Todo/TodoView.swift` — Current drop target + drop hint overlay; needs chat panel state integrated
- `Peninsula/Notch/NotchView.swift` — `dragDetector` with `.fileURL` onDrop; needs `.plainText` added
- `Peninsula/Todo/TodoRowView.swift` — Existing hover-visible buttons pattern; "Execute with AI" button goes here
- `Peninsula/Todo/TodoItem.swift` — Data model with `title`, `notes`, `link` fields used by agent

No external specs — requirements fully captured in decisions above and files listed.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `FileTodoService.shared.process(fileURL:)` — existing Claude Haiku pipeline; extend with `process(text:)` overload for text drag; refactor to return todos instead of adding silently
- `TodoRowView` — hover state (`isHovering`) and hover-visible button pattern already established; "Execute with AI" bolt button slots in here
- `TodoView` — `isDropTargeted` state + `onDrop` already wired; drop hint overlay to be replaced by pulsing glow
- `NotchView.dragDetector` — `.fileURL` onDrop + `dropTargeting` state; add `.plainText` to accepted types
- `TodoItem.notes` and `TodoItem.link` — already Codable fields; fed directly to EventKit agent

### Established Patterns
- Hover-visible buttons: `if isHovering { Button(...) }` in `TodoRowView` — consistent approach for "Execute with AI"
- Dark aesthetic: dark background, white/opacity typography, system rounded fonts
- Singleton services: `FileTodoService.shared`, `TodoStore.shared` — agent service should follow same pattern
- `@ObservedObject` + `ObservableObject` for reactive state
- All Swift files in `Peninsula/Todo/` auto-discovered by Xcode 16 PBXFileSystemSynchronizedRootGroup — no manual registration needed for new files in that folder
- `ANTHROPIC_API_KEY` from `ProcessInfo.processInfo.environment` — never hardcoded, never logged

### Integration Points
- `TodoView` — chat panel state (`.idle` / `.loading` / `.review([ClaudeTodo])`) replaces current drop hint overlay
- `NotchView.dragDetector` — add `.plainText` UTI to `onDrop` types; route text to same FileTodoService pipeline
- `TodoRowView` — add "Execute with AI" hover button → triggers new `CalendarAgentService`
- EventKit requires `NSCalendarsUsageDescription` in `Info.plist` + `requestAccess` at first use

</code_context>

<specifics>
## Specific Ideas

- The chat review panel is the KEY demo moment: drag meeting notes over notch → notch glows → "Creating todos..." → Claude presents extracted items → "Add all" — this should feel magical
- Todo details (notes + link) feed into the calendar event — these fields were seeded in Phase 2 specifically for agent integration
- Calendar agent is the "simplest credible demo" of AI agent execution — local, no auth, impressive enough

</specifics>

<deferred>
## Deferred Ideas

- **Gmail agent** — user mentioned this; deferred in favor of simpler calendar demo
- **Multi-agent routing** — Claude picks the right agent (calendar vs Gmail vs Jira) based on todo title. Belongs in its own phase.
- **Tabs / modes switcher** — multiple panels in the notch (Todo + Agents tab). Mentioned in prior phases; still deferred.
- **Non-calendar agent types** — Jira, Salesforce, Slack messaging. Future phases.

</deferred>

---

*Phase: 03-ai-interaction*
*Context gathered: 2026-03-18*
