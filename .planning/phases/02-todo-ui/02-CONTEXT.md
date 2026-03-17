# Phase 2: Todo UI - Context

**Gathered:** 2026-03-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Full todo list inside the notch panel: display, add, edit, complete, delete, and UserDefaults persistence. Also includes the notch counter badge — an incomplete-item count visible to the right of the collapsed notch.

Backend integration, agent task execution, tabs/modes switcher, and additional dynamic island content are explicitly out of scope.

</domain>

<decisions>
## Implementation Decisions

### Item Visual Design
- Priority badge: colored dot + label (● High / ● Normal / ● Low)
  - Red = High, Gray = Normal, Blue = Low
- Icon buttons (checkbox, delete, expand) visible on hover
- Items display: title, priority badge, checkbox, delete button, expand arrow

### Item Interactions
- Expand arrow reveals hidden detail panel: external link URL field + notes/description text area
- Checked item: strikethrough styling applied, item sinks to bottom of list below all active items
- Edit title: Claude's discretion — pick the simpler approach given the expand detail panel exists

### List Ordering
- Active items sorted by priority: High → Normal → Low
- Completed items always appear below all active items (regardless of priority)

### Adding Items
- Pressing Enter creates a new item; input field clears after
- Default priority is Normal
- Keyboard shortcut prefix to set priority at add time:
  - `!` prefix → High priority (e.g. `! Fix login bug`)
  - `!!` prefix → Low priority (e.g. `!! Clean up README`)
  - No prefix → Normal priority

### Notch Counter Badge
- When notch is collapsed: incomplete item count shown to the right of the notch
- Notch width extends on the right side only to accommodate the counter
- Counter disappears (no extra width) when all items are done or no items exist

### Empty State
- No empty state UI rendered — list area shows nothing when empty
- Input field always visible; user understands the affordance from context

### Claude's Discretion
- Edit title UX (inline click-to-edit vs edit inside expanded panel — pick whichever is simpler given the expand panel already exists)
- Input field placement (top or bottom of panel)
- Specific icon choices for buttons
- Hover state colors and transitions
- Exact notch width extension amount for the counter

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & Scope
- `.planning/REQUIREMENTS.md` — Full requirement spec: TODO-01 through TODO-06, INPUT-01 through INPUT-03, STORE-01 through STORE-03. Phase 2 covers all of these.

### Project Constraints
- `.planning/PROJECT.md` — Peninsula aesthetic guidelines, Swift/SwiftUI constraints, Xcode project management rules (file registration via xcodeproj gem or project.pbxproj), build verification steps, no CocoaPods/Carthage, entitlements must not break.

No external specs — requirements are fully captured in decisions above and the files listed.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Peninsula/Todo/TodoItem.swift` — Codable struct with id (UUID), title (String), priority (Priority enum: high/normal/low), isDone (Bool), createdAt (Date). Fully complete from Phase 1. Use as-is.
- `Peninsula/Notch/Gallery/GalleryModel.swift` — GalleryItem enum has only `.todo` case. GalleryModel.shared provides @Published currentItem. No tab navigation needed.

### Integration Points
- `Peninsula/Notch/NotchCompositeView.swift` — Replace `TodoPlaceholderView()` with the real `TodoView`. This is the single integration point for the todo panel.
- `Peninsula/Notch/NotchView.swift` — Handles collapsed notch rendering. The notch counter badge extends the right side of the notch here when status == .notched.
- `Peninsula/Notch/NotchViewModel.swift` — Controls notch sizing, animation, and open/close state. Any right-side width expansion for the counter must go through NotchViewModel sizing.

### Established Patterns
- Peninsula uses `@ObservedObject` / `@StateObject` + `ObservableObject` classes (not Combine subjects directly)
- Dark aesthetic: dark background, clean typography, consistent spacing via `vm.spacing`
- All new Swift files in `Peninsula/Todo/` are auto-discovered by Xcode 16's PBXFileSystemSynchronizedRootGroup — no manual xcodeproj registration needed for files added to that folder

</code_context>

<specifics>
## Specific Ideas

- User wants the ability to later delegate tasks to connector agents (calendar, Jira, Salesforce) — the item's external link field and notes field should use generic enough field names (`link`, `notes`) to support this future integration
- Dynamic island tabs/modes (switching between todo and other panels) is a strongly desired future direction — keep the panel structure modular

</specifics>

<deferred>
## Deferred Ideas

- **Agent task execution** — Delegate tasks to connector agents (calendar booking, Jira ticket creation, Salesforce updates, email drafting). Big future phase; external link field in items is the seed for this.
- **Tabs / modes switcher** — Multiple panels inside the dynamic island (e.g. Todo + Agents tab). User explicitly wants this; design in a future phase.
- **Additional dynamic island content** — What else goes in the notch beyond todos. To be discussed and designed in its own phase.
- **Priority editing after creation** — Change priority of an existing item. Out of scope per requirements; add to backlog.

</deferred>

---

*Phase: 02-todo-ui*
*Context gathered: 2026-03-17*
