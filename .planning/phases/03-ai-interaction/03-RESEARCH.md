# Phase 3: AI Interaction - Research

**Researched:** 2026-03-18
**Domain:** SwiftUI macOS — pulsing glow animations, text drag-and-drop, chat review UI state machine, EventKit calendar agent
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Drop Zone Animation**
- Animation style: Pulsing glow border — the notch border glows and pulses while content is being dragged over it
- No label/icon overlay — border animation only, no "Drop to create todos" label
- Auto-expand on drag hover: Notch opens automatically when content (text or file) is dragged near it — same behavior already implemented for files, extended to text drag
- Existing drop hint overlay (thin border + "Drop to create todos" text from Phase 2) is replaced by the new pulsing glow

**Text Drag Support**
- Drag selected text from any app (browser, Notes, TextEdit, etc.) works identically to dropping a file
- Implemented via `.plainText` UTI type in addition to `.fileURL` in `onDrop` and `dragDetector`
- Text content is passed directly to `FileTodoService` (or its successor) for Claude processing — same pipeline as files

**Chat Review Interface**
- After drop: notch enters loading state — animated thinking indicator (pulsing dots or spinner) with "Creating todos..." text replaces the normal todo list while the Claude API call is in progress
- After API response: chat panel appears inside the notch — Claude's message shows the extracted todo titles; two action buttons: "Add all" and "Dismiss"
- User may type a refinement (e.g. "make #2 high priority") — ONE round of free-text refinement is supported; Claude re-processes and shows updated list
- After "Add all": todos are added to today's list, chat panel disappears, normal todo list returns
- After "Dismiss": no todos added, normal todo list returns
- This replaces the Phase 2 "silent add" behavior — todos are never silently added; they always go through the review panel

**"Execute with AI" Button**
- Button lives on `TodoRowView` hover — visible on hover alongside existing delete/expand buttons (consistent with established pattern)
- Icon: lightning bolt (`bolt.fill`) to indicate agent execution
- Claude's discretion on exact placement within the hover row

**Agent Execution (Calendar)**
- Target: macOS EventKit (local Calendar.app integration — no OAuth, no external API)
- Input data: Claude agent receives `title`, `notes`, and `link` from the `TodoItem`
- Date inference: Claude extracts date/time hints from title and notes (e.g. "meeting tomorrow 3pm" → tomorrow at 15:00); falls back to today + 1 hour if no date hint found
- Event fields: event title = todo title; notes field = todo notes; URL field = todo link (if present)
- Requires: `NSCalendarsWriteOnlyAccessUsageDescription` in Info.plist + EventKit permission prompt at first use
- After success: todo is auto-checked (marked done) + brief "Calendar event created" toast near the notch
- Error handling: if EventKit permission denied or creation fails, show an error toast; Claude's discretion on exact messaging

### Claude's Discretion
- Exact pulsing glow animation parameters (timing, color, blur radius)
- Loading state visual (dots vs spinner, exact text)
- "Execute" button exact placement within hover row
- Toast appearance and dismiss timing
- Error toast messaging

### Deferred Ideas (OUT OF SCOPE)
- Gmail agent
- Multi-agent routing (Claude picks the right agent based on todo title)
- Tabs / modes switcher
- Non-calendar agent types (Jira, Salesforce, Slack)

</user_constraints>

---

## Summary

Phase 3 adds three distinct AI-powered features on top of the existing todo UI: a pulsing glow drop zone that replaces the Phase 2 border overlay, a chat-style review panel that intercepts Claude's todo extraction results before committing them, and an "Execute with AI" button that invokes EventKit to create a calendar event from a todo item.

The technical complexity is distributed across four integration seams: (1) extending `onDrop` to accept `.plainText` UTI from external apps in both `NotchView.dragDetector` and `TodoView`; (2) refactoring `FileTodoService` to return extracted todos instead of adding them silently, introducing a three-state view model (`.idle` / `.loading` / `.review([ClaudeTodo])`); (3) building a compact chat panel UI inside `TodoView` that supports one round of user refinement via a second Claude API call; and (4) building `CalendarAgentService` using the macOS 14+ EventKit async API (`requestWriteOnlyAccessToEvents()` + `EKEvent` creation).

The app runs on macOS 14+ and is NOT sandboxed, so only the `NSCalendarsWriteOnlyAccessUsageDescription` Info.plist key is required — no additional entitlements file changes are needed. All new Swift files in `Peninsula/Todo/` are auto-discovered by Xcode 16 PBXFileSystemSynchronizedRootGroup.

**Primary recommendation:** Implement in four waves: (1) pulsing glow border + text drag UTI; (2) FileTodoService refactor + chat review state machine; (3) chat panel UI with refinement; (4) CalendarAgentService + "Execute with AI" button + toast.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| EventKit | macOS 14+ built-in | Create calendar events locally | Only Apple framework for Calendar.app integration — no OAuth, no external API |
| SwiftUI | built-in | Drop zone animation, chat panel, toast | Already used throughout; no new dependencies |
| UniformTypeIdentifiers | built-in | `.plainText` UTI for text drag-and-drop | Already imported in `NotchView.swift` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Combine | built-in | Observable state publishing | Already used for `TodoStore` → `NotchViewModel` bridge |
| PDFKit | built-in | PDF text extraction | Already used in `FileTodoService` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-rolled pulsing glow | Apple Intelligence glow library (GitHub) | External dependency — not worth it. SwiftUI `.overlay` + `.blur` + `.repeatForever` achieves the effect natively |
| Simple custom toast | `AlertToast` / `SimpleToast` SPM packages | SPM packages add complexity; a 30-line `ZStack` overlay with `DispatchQueue.main.asyncAfter` dismiss timer is sufficient for this demo |
| `requestFullAccessToEvents()` | `requestWriteOnlyAccessToEvents()` | Write-only is the correct access level since we only create events, not read/edit them |

**Installation:** No new package dependencies. All features use built-in Apple frameworks.

---

## Architecture Patterns

### Recommended Project Structure

New files, all in `Peninsula/Todo/` (auto-discovered by Xcode 16):

```
Peninsula/Todo/
├── FileTodoService.swift       # MODIFY: add process(text:), refactor to return todos
├── TodoView.swift              # MODIFY: add DropReviewState enum, chat panel
├── TodoRowView.swift           # MODIFY: add "Execute with AI" bolt button
├── CalendarAgentService.swift  # NEW: EventKit calendar event creation
└── ToastView.swift             # NEW: brief success/error toast overlay
```

### Pattern 1: Drop Review State Machine

**What:** `TodoView` owns a `@State private var dropReviewState: DropReviewState` enum that drives what the view renders.

**When to use:** Whenever a single view needs to switch between mutually exclusive content regions driven by async operations.

```swift
// In TodoView.swift
enum DropReviewState {
    case idle
    case loading                     // Claude API call in progress
    case review([ClaudeTodo])        // Extracted todos awaiting user confirmation
    case refining(String, [ClaudeTodo])  // User typed refinement, awaiting re-call
}
```

The view body switches on this state:
- `.idle` → normal todo list (existing content)
- `.loading` → loading indicator ("Creating todos...")
- `.review(todos)` → chat panel listing extracted titles + "Add all" / "Dismiss"
- `.refining` → loading indicator again during second Claude call

### Pattern 2: FileTodoService Refactor — Return Instead of Add

**What:** `FileTodoService` currently calls `TodoStore.shared.add()` directly. Phase 3 refactors it to return `[ClaudeTodo]` so the caller (TodoView) can show the review panel.

```swift
// Source: existing FileTodoService.swift pattern, refactored
class FileTodoService {
    static let shared = FileTodoService()

    // NEW: returns extracted todos for review, never adds directly
    func process(fileURL: URL) async throws -> [ClaudeTodo] { ... }
    func process(text: String) async throws -> [ClaudeTodo] { ... }
    func refine(originalTodos: [ClaudeTodo], instruction: String) async throws -> [ClaudeTodo] { ... }

    // ClaudeTodo promoted to internal (not private) so TodoView can use it
    struct ClaudeTodo: Decodable {
        let title: String
        let priority: String   // "high" | "normal" | "low"
    }
}
```

The caller in `TodoView` manages state transitions:
```swift
dropReviewState = .loading
Task {
    do {
        let todos = try await FileTodoService.shared.process(text: droppedText)
        await MainActor.run { dropReviewState = .review(todos) }
    } catch {
        await MainActor.run { dropReviewState = .idle }
    }
}
```

### Pattern 3: Text Drag via `.plainText` UTI

**What:** Add `.plainText` alongside `.fileURL` in both `NotchView.dragDetector` and `TodoView.onDrop`.

**Source confirmed:** Eclectic Light Company (2024) — use `UTType.plainText` identifier `"public.utf8-plain-text"`. Load via `loadItem(forTypeIdentifier:)` and decode as UTF-8 data.

```swift
// In NotchView.dragDetector and TodoView body — add .plainText to accepted types
.onDrop(of: [.fileURL, .plainText], isTargeted: $dropTargeting) { providers in
    for provider in providers {
        // Handle file drop
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                // trigger review flow with fileURL
            }
        }
        // Handle plain text drop
        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let text = String(data: data, encoding: .utf8) else { return }
                // trigger review flow with text
            }
        }
    }
    return true
}
```

### Pattern 4: Pulsing Glow Border Animation

**What:** Replace the Phase 2 `strokeBorder` drop hint overlay with a pulsing glow effect using layered `.blur` + `.opacity` animation with `.repeatForever`.

**Source confirmed:** SwiftUI glow pattern from multiple 2024 sources — stack multiple stroked `RoundedRectangle` layers with different blur values; animate opacity with `.repeatForever(autoreverses: true)`.

```swift
// In TodoView — replaces the existing `if isDropTargeted { RoundedRectangle... }` block
if isDropTargeted {
    RoundedRectangle(cornerRadius: 12)
        .strokeBorder(Color.white.opacity(0.9), lineWidth: 2)
        .blur(radius: 0)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.6), lineWidth: 6)
                .blur(radius: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 12)
                .blur(radius: 8)
        )
        .opacity(glowPulse ? 1.0 : 0.4)  // @State private var glowPulse = false
        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: glowPulse)
        .onAppear { glowPulse = true }
        .onDisappear { glowPulse = false }
        .padding(8)
        .allowsHitTesting(false)
}
```

### Pattern 5: CalendarAgentService — EventKit macOS 14+

**What:** Singleton service that uses the new async EventKit API to create a calendar event from a `TodoItem`.

**Critical API note (macOS 14+):** Use `requestWriteOnlyAccessToEvents()` (NOT the deprecated `requestAccess(to: .event)`). Add `NSCalendarsWriteOnlyAccessUsageDescription` to `Info.plist`.

```swift
// Source: Apple EventKit documentation, WWDC23 session
import EventKit

class CalendarAgentService {
    static let shared = CalendarAgentService()
    private let store = EKEventStore()

    func createEvent(from item: TodoItem) async throws {
        // 1. Request write-only access (macOS 14+ API)
        guard try await store.requestWriteOnlyAccessToEvents() else {
            throw CalendarAgentError.accessDenied
        }

        // 2. Parse date/time from item title and notes (Claude call)
        let eventDate = try await inferEventDate(from: item)

        // 3. Create and save EKEvent
        let event = EKEvent(eventStore: store)
        event.title = item.title
        event.notes = item.notes
        if let linkStr = item.link, let url = URL(string: linkStr) {
            event.url = url
        }
        event.startDate = eventDate
        event.endDate = eventDate.addingTimeInterval(3600)  // 1-hour default duration
        event.calendar = store.defaultCalendarForNewEvents

        try store.save(event, span: .thisEvent)
    }
}

enum CalendarAgentError: Error {
    case accessDenied
    case noDefaultCalendar
    case saveFailed(Error)
}
```

### Pattern 6: Toast Overlay

**What:** A brief `ZStack` overlay at the bottom of `TodoView` that auto-dismisses after 2 seconds.

```swift
// In TodoView — overlay on top of the main VStack
.overlay(alignment: .bottom) {
    if let toastMessage = toastMessage {  // @State private var toastMessage: String? = nil
        Text(toastMessage)
            .font(.system(.caption, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.15)))
            .padding(.bottom, 8)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}
.animation(.easeInOut(duration: 0.25), value: toastMessage)
```

Dismiss via:
```swift
func showToast(_ message: String) {
    withAnimation { toastMessage = message }
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        withAnimation { toastMessage = nil }
    }
}
```

### Anti-Patterns to Avoid

- **Silent add (Phase 2 behavior):** `FileTodoService` must never call `TodoStore.shared.add()` directly in Phase 3 — all additions go through the review panel.
- **Single `onDrop` for both text and file:** Don't conflate providers — check `hasItemConformingToTypeIdentifier` before loading each type.
- **Using deprecated `requestAccess(to: .event)`:** This API is deprecated on macOS 14+; use `requestWriteOnlyAccessToEvents()` instead. Deprecated API still works but will log warnings.
- **Recreating `EKEventStore` per call:** Create one `EKEventStore` instance per service singleton — the store is stateful and should persist across calls.
- **Pulsing glow using scale animation:** Scale animation moves the border visually; use opacity animation on the glow layers instead, and keep `allowsHitTesting(false)` so the overlay doesn't block the drop target.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Calendar event creation | Custom AppleScript, custom OAuth, custom ICS file write | `EventKit` / `EKEventStore` | EventKit is local, no auth required, directly integrates with Calendar.app |
| Text drag-and-drop parsing | Custom pasteboard reading with NSPasteboard | `NSItemProvider.loadItem(forTypeIdentifier:)` in `onDrop` | Already the established pattern in this codebase (file drops use the same API) |
| Permission state tracking | Custom UserDefaults flags | `EKEventStore.authorizationStatus(for: .event)` | EventKit tracks this natively; checking on every call is safe |
| Date/time parsing from text | Custom regex date parser | Send title + notes to Claude in the same API call | Claude is already in the loop; ask it to extract date/time as JSON alongside the event fields |
| Toast / notification UI | OS-level notification (NSUserNotification / UNUserNotificationCenter) | Simple SwiftUI overlay with auto-dismiss | Notifications require additional permissions and appear outside the notch; an inline overlay is more cohesive |

**Key insight:** The date inference for calendar events is best delegated to Claude as part of the `CalendarAgentService` — include a Claude API call that returns `{ "startDate": "ISO8601", "title": "..." }` rather than writing a custom NLP parser. Claude already has the API key infrastructure in place.

---

## Common Pitfalls

### Pitfall 1: Text Drop UTI Mismatch

**What goes wrong:** `.plainText` is the SwiftUI `UTType` but the actual identifier string when loading is `"public.utf8-plain-text"` for UTF-8 text or `"public.plain-text"` for generic plain text. External apps (browsers, Notes) may provide either.

**Why it happens:** The UTType API in SwiftUI normalizes type identifiers at the declaration level, but `loadItem(forTypeIdentifier:)` requires the exact underlying string. Different apps export different subtypes.

**How to avoid:** Check `hasItemConformingToTypeIdentifier("public.utf8-plain-text")` first; fall back to `"public.plain-text"`. Alternatively, use `loadObject(ofClass: String.self)` which handles both automatically:
```swift
provider.loadObject(ofClass: String.self) { string, _ in
    guard let text = string else { return }
    // use text
}
```

**Warning signs:** Drop completes (returns true) but no text content is received; `loadItem` completion receives `nil` data.

### Pitfall 2: EventKit Permission Only Prompts Once

**What goes wrong:** If the user denies calendar access on the first prompt, subsequent calls to `requestWriteOnlyAccessToEvents()` return `false` silently without prompting again. The app appears to silently fail.

**Why it happens:** macOS only prompts once; subsequent requests return the cached authorization status.

**How to avoid:** Always check `EKEventStore.authorizationStatus(for: .event)` before attempting to request. If status is `.denied`, show an error toast directing the user to System Settings > Privacy & Security > Calendars. Never assume the prompt will fire.

**Warning signs:** `requestWriteOnlyAccessToEvents()` returns `false` but no permission prompt appeared.

### Pitfall 3: `isDropTargeted` Fires for Both File and Text

**What goes wrong:** `NotchView.dragDetector` currently has `.onDrop(of: [.fileURL], isTargeted: $dropTargeting)`. When `.plainText` is added, `dropTargeting` fires for text drags too and the notch opens — which is correct. BUT if `TodoView` also has its own drop target for `.fileURL` only, text drops will be caught by `dragDetector` but miss `TodoView`'s handler.

**Why it happens:** Two overlapping `onDrop` targets with different type lists.

**How to avoid:** Add `.plainText` to BOTH `onDrop` targets (NotchView dragDetector AND TodoView body) simultaneously — exactly as described in CONTEXT.md. Both need the same type list to handle drops consistently regardless of where the content lands.

### Pitfall 4: `@State` vs `@ObservedObject` for Review State

**What goes wrong:** Placing `DropReviewState` inside `TodoView` as `@State` is correct. Placing it inside `FileTodoService` or a new `ObservableObject` creates an extra layer of indirection that's unnecessary for this single-view state.

**Why it happens:** Over-engineering singleton services to own UI state.

**How to avoid:** `dropReviewState: DropReviewState` lives in `TodoView` as `@State`. `FileTodoService` only does async work and returns data — it has no opinion about UI state.

### Pitfall 5: macOS 14 EventKit Deprecation Warning Storm

**What goes wrong:** Using `requestAccess(to: .event)` (the pre-macOS 14 API) compiles fine on macOS 14/15 but triggers deprecation warnings. Since the build target is macOS 14.0, the new API is fully available.

**How to avoid:** Use `requestWriteOnlyAccessToEvents()` exclusively. No `#available` guard needed since the deployment target is macOS 14.0.

### Pitfall 6: Info.plist Key Missing → Silent Permission Failure

**What goes wrong:** On macOS 14+, if `NSCalendarsWriteOnlyAccessUsageDescription` is absent from `Info.plist`, the system will silently refuse to show the permission prompt and EventKit will return `.denied` immediately.

**How to avoid:** Add the key to `Peninsula/Info.plist` before any EventKit code runs. The project currently has only `SUFeedURL` in Info.plist — this is a required addition.

---

## Code Examples

### Handling Text Drop from External App

```swift
// Source: Eclectic Light Company macOS drag-and-drop article (May 2024)
// Works for text selected in Safari, Notes, TextEdit, etc.
provider.loadObject(ofClass: String.self) { string, error in
    guard let text = string, !text.isEmpty else { return }
    DispatchQueue.main.async {
        // Trigger review flow
    }
}
```

### EventKit Write-Only Access + Event Creation (macOS 14+)

```swift
// Source: Apple Developer Documentation - requestWriteOnlyAccessToEvents
// Source: WWDC23 "Discover Calendar and EventKit"
import EventKit

let store = EKEventStore()

// Request write-only access
let granted = try await store.requestWriteOnlyAccessToEvents()
guard granted else { throw CalendarAgentError.accessDenied }

// Create event
let event = EKEvent(eventStore: store)
event.title = "Team standup"
event.startDate = Date()
event.endDate = Date().addingTimeInterval(3600)
event.notes = "Optional notes"
event.url = URL(string: "https://example.com/ticket/123")
event.calendar = store.defaultCalendarForNewEvents
try store.save(event, span: .thisEvent)
```

### Info.plist Entry Required

```xml
<!-- Add to Peninsula/Info.plist -->
<key>NSCalendarsWriteOnlyAccessUsageDescription</key>
<string>Peninsula needs calendar access to create events from your todos</string>
```

### Claude API Call for Date Inference

```swift
// Extend the existing Claude API pattern in FileTodoService / CalendarAgentService
// Ask Claude to extract event date as part of the calendar agent prompt:
let systemPrompt = """
You are a calendar event assistant. Given a todo item (title, notes, link), \
extract the event details. Return ONLY valid JSON with keys: \
"startISO" (ISO 8601 date-time, local time), "title" (string). \
If no date/time found, use tomorrow at 10:00 AM local time. \
No prose, no markdown fences.
"""
// Same ANTHROPIC_API_KEY + claude-haiku-4-5 + URLSession pattern as FileTodoService
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `requestAccess(to: .event)` | `requestWriteOnlyAccessToEvents()` | macOS 14 / iOS 17 (2023) | Write-only is now the minimum required access; old API is deprecated |
| `NSCalendarsUsageDescription` | `NSCalendarsWriteOnlyAccessUsageDescription` or `NSCalendarsFullAccessUsageDescription` | macOS 14 / iOS 17 (2023) | Old key no longer recognized by the system on macOS 14+ |
| Manual `onDrop(of: ["public.file-url"])` string | `onDrop(of: [.fileURL, .plainText])` UTType array | SwiftUI on macOS 12+ | UTType API is type-safe; string identifiers still work but UTType is canonical |

**Deprecated/outdated in this codebase:**
- `requestAccess(to: .event)`: Deprecated on macOS 14, DO NOT use
- `NSCalendarsUsageDescription` plist key: Replaced by write-only/full-access variants on macOS 14+
- `FileTodoService.process(fileURL:)` silent-add behavior: Replaced by returning `[ClaudeTodo]` for review

---

## Open Questions

1. **Claude date inference reliability**
   - What we know: Claude Haiku handles natural language date extraction well for common patterns ("meeting tomorrow 3pm", "call Friday")
   - What's unclear: Edge cases like "ASAP", "EOD", "next sprint" — these have no clear date
   - Recommendation: Instruct Claude to fall back to "tomorrow at 10:00 AM" for ambiguous cases; don't block event creation on parsing uncertainty

2. **`EKEvent.url` field availability**
   - What we know: `EKEvent` has a `url: URL?` property documented in Apple's API
   - What's unclear: Some community reports indicate the `notes` field may be restricted on macOS when the app is not in the App Store (hardened runtime). The app currently has `com.apple.security.cs.disable-library-validation: true` in entitlements, which suggests it runs with some hardened runtime relaxations.
   - Recommendation: Test EventKit notes write at runtime; if it silently fails, document it and omit gracefully

3. **Refinement prompt token budgeting**
   - What we know: A second Claude API call is made with the original content + user instruction + previous todo list
   - What's unclear: The combined prompt may approach token limits for large documents
   - Recommendation: Pass only the previous `[ClaudeTodo]` JSON array (not the full original content) plus the user's refinement instruction in the second call

---

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation — `requestWriteOnlyAccessToEvents()`: https://developer.apple.com/documentation/eventkit/ekeventstore/4162274-requestwriteonlyaccesstoeventswi
- Apple Developer Documentation — `requestFullAccessToEvents()`: https://developer.apple.com/documentation/eventkit/ekeventstore/requestfullaccesstoevents(completion:)
- Apple Developer Documentation — Accessing Calendar using EventKit: https://developer.apple.com/documentation/EventKit/accessing-calendar-using-eventkit-and-eventkitui
- Apple Developer Documentation — `NSCalendarsWriteOnlyAccessUsageDescription`: https://developer.apple.com/documentation/bundleresources/information-property-list/nscalendarswriteonlyaccessusagedescription
- Apple WWDC23 — Discover Calendar and EventKit: https://developer.apple.com/videos/play/wwdc2023/10052/
- Apple TN3153 — Adopting API changes for EventKit in iOS 17, macOS 14: https://developer.apple.com/documentation/technotes/tn3153-adopting-api-changes-for-eventkit-in-ios-macos-and-watchos
- Existing codebase — `FileTodoService.swift`, `NotchView.swift`, `TodoView.swift`, `TodoRowView.swift`, `TodoItem.swift`

### Secondary (MEDIUM confidence)
- Eclectic Light Company — SwiftUI on macOS: Drag and drop (May 2024): https://eclecticlight.co/2024/05/21/swiftui-on-macos-drag-and-drop-and-more/ — confirms `loadObject(ofClass: String.self)` for text drop
- Create with Swift — Getting access to the user's calendar: https://www.createwithswift.com/getting-access-to-the-users-calendar/ — confirms `requestFullAccessToEvents()` async pattern
- Livsy Code — Apple Intelligence-Style Glow Effect in SwiftUI: https://livsycode.com/swiftui/an-apple-intelligence-style-glow-effect-in-swiftui/ — confirms layered blur + opacity pulse pattern
- Medium (Thibault Giraudon) — How to Add Events Using SwiftUI and EventKit: https://medium.com/@thibault.giraudon/how-to-add-events-to-your-calendar-using-swiftui-and-eventkit-9b81528bf397

### Tertiary (LOW confidence — needs runtime validation)
- Community reports about `EKEvent.notes` field accessibility on macOS hardened runtime — not verified against official docs; test at implementation time

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all frameworks are built-in Apple APIs, confirmed against documentation
- Architecture (FileTodoService refactor, state machine): HIGH — follows existing patterns in codebase
- EventKit async API (macOS 14+): HIGH — confirmed against Apple official docs
- Text drag UTI: MEDIUM — primary pattern confirmed via Eclectic Light Company + Apple forums; exact provider behavior for every app may vary
- Pulsing glow animation: MEDIUM — pattern verified from multiple 2024 sources; exact visual parameters are Claude's discretion per CONTEXT.md
- EKEvent.notes field behavior: LOW — community reports of occasional issues; needs runtime test

**Research date:** 2026-03-18
**Valid until:** 2026-04-18 (EventKit API stable; SwiftUI animation APIs stable)
