# Requirements: Peninsula Todo

**Defined:** 2026-03-17
**Core Value:** AI-created tasks from Superhuman Go surface instantly in the macOS notch — no window switching, no app context loss.

## v1 Requirements

### Notch Shell

- [x] **NOTCH-01**: Notch expands on hover using Peninsula's existing animation and hover detection logic
- [x] **NOTCH-02**: Notch collapses when mouse leaves the notch area
- [x] **NOTCH-03**: Peninsula's window management and display code is preserved (no regression)

### Todo Display

- [x] **TODO-01**: Expanded notch shows a scrollable list of todo items
- [x] **TODO-02**: Each item displays its title
- [x] **TODO-03**: Each item displays a priority badge (High / Normal / Low) with distinct visual styling
- [x] **TODO-04**: Each item has a checkbox; checking it applies strikethrough styling and marks item done
- [x] **TODO-05**: Each item has a delete button to remove it from the list
- [x] **TODO-06**: List is scrollable when items overflow the notch panel height

### Todo Input

- [x] **INPUT-01**: An input field at the bottom (or top) of the panel allows typing a new todo title
- [x] **INPUT-02**: Pressing Enter/Return adds the item to the list with Normal priority by default
- [x] **INPUT-03**: Input field clears after submission

### Persistence

- [x] **STORE-01**: Todo items persist across app relaunches via UserDefaults
- [x] **STORE-02**: TodoItem is a Codable struct with fields: id (UUID), title (String), priority (enum: high/normal/low), isDone (Bool), createdAt (Date)
- [x] **STORE-03**: Adding, completing, and deleting items are immediately persisted

## v2 Requirements

### Backend Integration

- **API-01**: Replace UserDefaults with polling/subscribing to Superhuman Go database
- **API-02**: Items created by Superhuman Go agent appear automatically without manual input
- **API-03**: Priority set by LLM agent is reflected in the UI

### Enhanced Items

- **ENH-01**: Optional Jira ticket link on an item (tappable, opens in browser)
- **ENH-02**: Item detail expansion showing LLM-generated description
- **ENH-03**: Due date field per item

## Out of Scope

| Feature | Reason |
|---------|--------|
| Peninsula's App Switcher (cmd-tab) | Gutted — not needed for todo use case |
| Notification Center | Gutted — not in scope |
| Tray (file drop) | Gutted — not in scope |
| Timer | Gutted — not in scope |
| Settings panel | Gutted — not in scope |
| iOS/iPadOS support | macOS notch only |
| Priority editing after creation | Can add later; not needed for demo |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| NOTCH-01 | Phase 1 | Complete |
| NOTCH-02 | Phase 1 | Complete |
| NOTCH-03 | Phase 1 | Complete |
| STORE-02 | Phase 1 | Complete |
| TODO-01 | Phase 2 | Complete |
| TODO-02 | Phase 2 | Complete |
| TODO-03 | Phase 2 | Complete |
| TODO-04 | Phase 2 | Complete |
| TODO-05 | Phase 2 | Complete |
| TODO-06 | Phase 2 | Complete |
| INPUT-01 | Phase 2 | Complete |
| INPUT-02 | Phase 2 | Complete |
| INPUT-03 | Phase 2 | Complete |
| STORE-01 | Phase 2 | Complete |
| STORE-03 | Phase 2 | Complete |

**Coverage:**
- v1 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-17*
*Last updated: 2026-03-17 after roadmap creation*
