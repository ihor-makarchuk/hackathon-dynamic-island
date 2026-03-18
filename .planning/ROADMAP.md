# Roadmap: Peninsula Todo

## Overview

Fork Peninsula, gut the gallery views, replace with a single TodoView. Phase 1 establishes the working notch shell with the gallery stripped down to a single todo slot. Phase 2 delivers the full todo UI — display, input, and UserDefaults persistence — resulting in a demoable hackathon app.

## Phases

**Phase Numbering:**
- Integer phases (1, 2): Planned milestone work
- Decimal phases (1.1, 1.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Shell** - Peninsula gallery gutted; notch expands/collapses with a single TodoView placeholder wired in (completed 2026-03-17)
- [x] **Phase 2: Todo UI** - Full todo list with display, input, and UserDefaults persistence (completed 2026-03-18)
- [ ] **Phase 3: AI Interaction** - Text/file drop with chat-style review UI + "Execute with AI" agent button on todo items (calendar/Gmail demo)

## Phase Details

### Phase 1: Shell
**Goal**: The notch opens and closes correctly with a single TodoView slot in place of all gallery views
**Depends on**: Nothing (first phase)
**Requirements**: NOTCH-01, NOTCH-02, NOTCH-03, STORE-02
**Success Criteria** (what must be TRUE):
  1. Hovering over the macOS notch expands it using Peninsula's existing animation
  2. Moving the mouse away from the notch collapses it back to the bar
  3. No Peninsula gallery tabs appear — only the todo panel slot is rendered
  4. TodoItem Codable struct compiles with id, title, priority, isDone, createdAt fields
**Plans:** 1/1 plans complete
Plans:
- [ ] 01-01-PLAN.md — Clone Peninsula, gut gallery to single .todo case, create TodoItem Codable struct

### Phase 2: Todo UI
**Goal**: Users can view, add, complete, and delete todo items that survive app relaunches
**Depends on**: Phase 1
**Requirements**: TODO-01, TODO-02, TODO-03, TODO-04, TODO-05, TODO-06, INPUT-01, INPUT-02, INPUT-03, STORE-01, STORE-03
**Success Criteria** (what must be TRUE):
  1. Expanded notch shows a scrollable list of todo items with title and priority badge (High/Normal/Low)
  2. Checking an item's checkbox applies strikethrough styling and marks it done
  3. Clicking delete on an item removes it from the list immediately
  4. Typing in the input field and pressing Enter adds a new Normal-priority item and clears the field
  5. Todo items are still present after quitting and relaunching the app
**Plans**: TBD

### Phase 3: AI Interaction
**Goal**: Text and file drag-and-drop with animated drop zone, a chat-style review UI that lets users confirm/edit extracted todos before adding, and an "Execute with AI" button on todo items that demos AI agent task execution (calendar event creation or Gmail message)
**Depends on**: Phase 2
**Requirements**: TBD
**Success Criteria** (what must be TRUE):
  1. Dragging a text selection or file over the notch triggers an animated drop zone overlay
  2. Dropped content is processed by Claude and extracted todos appear in a review panel before being added
  3. User can confirm, edit, or dismiss extracted todos from the review panel
  4. Each todo item has an "Execute with AI" button that triggers an AI agent
  5. The agent demo executes at least one task type (calendar event or Gmail message) from the todo title
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Shell | 1/1 | Complete    | 2026-03-17 |
| 2. Todo UI | 4/4 | Complete   | 2026-03-18 |
| 3. AI Interaction | TBD | Pending | — |
