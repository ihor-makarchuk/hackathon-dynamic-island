# Phase 2: Todo UI - Context

**Gathered:** 2026-03-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Full todo list inside the notch panel: display, add, edit, complete, delete, and UserDefaults persistence. Also includes:
- **Date navigation** — horizontal day carousel to view/add todos by day (past and future)
- **Notch counter badge** — incomplete item count visible to the right of the collapsed notch
- **File drop → AI todo creation** — drag a file onto the notch to generate todos via Claude API

Backend integration with Superhuman Go, agent task execution, and tabs/modes switcher are explicitly out of scope.

</domain>

<decisions>
## Implementation Decisions

### Data Model
- `TodoItem` gains a `dueDate: Date` field (defaults to today at creation time)
- No migration needed — starting fresh, no existing user data to preserve
- `TodoItem` fields: id (UUID), title (String), priority (Priority), isDone (Bool), createdAt (Date), dueDate (Date)
- Optional fields for future agent integration: `link: String?`, `notes: String?`

### Date Navigation (Day Carousel)
- Horizontal date strip at the top of the panel with left/right arrows to navigate days
- Opens on today by default
- All todo operations (add, view, complete, delete) operate on the currently selected day
- Past days are fully functional — can still add/edit/complete items on past days

### Item Visual Design
- Priority badge: colored dot + label (● High / ● Normal / ● Low)
  - Red = High, Gray = Normal, Blue = Low
- Icon buttons (checkbox, delete, expand) visible on hover
- Items display: title, priority badge, checkbox, delete button, expand arrow

### Item Interactions
- Expand arrow reveals hidden detail panel: external link (`link`) field + notes/description (`notes`) text area
- Checked item: strikethrough styling applied, item sinks to bottom of list below all active items
- Edit title: Claude's discretion — pick the simpler approach given the expand detail panel exists

### List Ordering
- Active items sorted by priority: High → Normal → Low
- Completed items always appear below all active items (regardless of priority)

### Adding Items
- Pressing Enter creates a new item assigned to the currently selected day; input field clears after
- Default priority is Normal
- Keyboard shortcut prefix to set priority at add time:
  - `!` prefix → High priority (e.g. `! Fix login bug`)
  - `!!` prefix → Low priority (e.g. `!! Clean up README`)
  - No prefix → Normal priority

### Notch Counter Badge
- When notch is collapsed: incomplete item count for today shown to the right of the notch
- Notch width extends on the right side only to accommodate the counter
- Counter disappears (no extra width) when today has no incomplete items

### Empty State
- No empty state UI rendered — list area shows nothing when empty for the selected day
- Input field always visible; user understands the affordance from context

### File Drop → AI Todo Creation
- Supported file types: `.txt`, `.md`, `.pdf`
- Drag a file onto the notch area: notch expands on drag hover
- File content extracted (PDF → plain text), then sent to Claude API (claude-haiku-4-5) for todo extraction
- API key read from `ANTHROPIC_API_KEY` environment variable
- Generated todos added directly to today's list (no preview/confirmation step)
- Claude prompt goal: extract actionable todo items from the file content with appropriate priorities

### Claude's Discretion
- Edit title UX (inline click-to-edit vs edit inside expanded panel — pick whichever is simpler)
- Input field placement (top or bottom of panel)
- Specific icon choices for buttons
- Hover state colors and transitions
- Exact notch width extension amount for the counter
- Date carousel visual design (pill dates, just day names, relative labels like "Today / Yesterday")
- PDF text extraction approach (PDFKit is available in macOS SDK — no third-party dependency)
- Haiku prompt engineering for todo extraction

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & Scope
- `.planning/REQUIREMENTS.md` — Full requirement spec: TODO-01 through TODO-06, INPUT-01 through INPUT-03, STORE-01 through STORE-03. Phase 2 covers all of these plus the new date navigation and file drop capabilities added during context discussion.

### Project Constraints
- `.planning/PROJECT.md` — Peninsula aesthetic guidelines, Swift/SwiftUI constraints, Xcode project management rules (file registration via xcodeproj gem or project.pbxproj), build verification steps, no CocoaPods/Carthage, entitlements must not break.

No external specs — requirements are fully captured in decisions above and the files listed.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Peninsula/Todo/TodoItem.swift` — Codable struct with id, title, priority, isDone, createdAt. **Needs `dueDate: Date` and optional `link: String?`, `notes: String?` fields added.** Priority enum (high/normal/low) is complete.
- `Peninsula/Notch/Gallery/GalleryModel.swift` — GalleryItem enum has only `.todo` case. GalleryModel.shared provides @Published currentItem. No tab navigation needed.

### Integration Points
- `Peninsula/Notch/NotchCompositeView.swift` — Replace `TodoPlaceholderView()` with the real `TodoView`. This is the single integration point for the todo panel.
- `Peninsula/Notch/NotchView.swift` — Handles collapsed notch rendering. The notch counter badge extends the right side of the notch here when `status == .notched`.
- `Peninsula/Notch/NotchViewModel.swift` — Controls notch sizing, animation, and open/close state. Right-side width expansion for the counter must go through NotchViewModel sizing. Also the target for drag-hover expansion trigger.

### Established Patterns
- Peninsula uses `@ObservedObject` / `@StateObject` + `ObservableObject` classes (not Combine publishers directly)
- Dark aesthetic: dark background, clean typography, consistent spacing via `vm.spacing`
- All new Swift files in `Peninsula/Todo/` are auto-discovered by Xcode 16's PBXFileSystemSynchronizedRootGroup — no manual xcodeproj registration needed for files in that folder
- Peninsula previously had a Tray feature (file drop) that was gutted — drag-drop window handling patterns may exist in git history if needed

### macOS SDK Available
- `PDFKit` — available in macOS SDK, no extra dependency needed for PDF text extraction
- `NSOpenPanel` / drag-drop via `NSView.registerForDraggedTypes` or SwiftUI `.onDrop` modifier

</code_context>

<specifics>
## Specific Ideas

- User wants item `link` and `notes` fields to be generic enough to support future agent integrations (calendar booking, Jira creation, Salesforce, email drafting) — don't name them Jira-specific
- Drag and drop is a key demo moment: notch expands on drag hover, making the interaction feel alive
- The date carousel enables "what did I do yesterday / what's coming up tomorrow" use cases — important for the Superhuman Go vision of surfacing AI-created tasks over time

</specifics>

<deferred>
## Deferred Ideas

- **Agent task execution** — Delegate tasks to connector agents (calendar booking, Jira ticket creation, Salesforce updates, email drafting). `link` and `notes` fields in TodoItem are the seed for this.
- **Tabs / modes switcher** — Multiple panels inside the dynamic island (e.g. Todo + Agents tab). User explicitly wants this; design in a future phase.
- **Additional dynamic island content** — What else goes in the notch beyond todos. To be discussed and designed in its own phase.
- **Priority editing after creation** — Change priority on an existing item post-creation. Out of scope per requirements; add to backlog.

</deferred>

---

*Phase: 02-todo-ui*
*Context gathered: 2026-03-17 (updated with date navigation + file drop)*
