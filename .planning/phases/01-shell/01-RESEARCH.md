# Phase 1: Shell - Research

**Researched:** 2026-03-17
**Domain:** Swift/SwiftUI macOS — Peninsula fork, gallery gutting, Codable model
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| NOTCH-01 | Notch expands on hover using Peninsula's existing animation and hover detection logic | `NotchHoverView.reevaluateHover()` + `NotchViewModel.notchPop()` — no changes needed; keep intact |
| NOTCH-02 | Notch collapses when mouse leaves the notch area | `NotchHoverView.onHover` closure calls `notchViewModel.notchClose()` — preserve as-is |
| NOTCH-03 | Peninsula's window management and display code is preserved (no regression) | `NotchWindow`, `NotchWindowController`, `AppDelegate`, `NotchViewModels` must be untouched; only `GalleryModel` and `NotchCompositeView` change |
| STORE-02 | TodoItem Codable struct with id (UUID), title (String), priority (enum), isDone (Bool), createdAt (Date) | New file `TodoItem.swift` added to the Peninsula target via xcodeproj gem |
</phase_requirements>

---

## Summary

Phase 1 forks Peninsula and strips its gallery to a single placeholder slot, while establishing the `TodoItem` data model. The animation/hover/window machinery in `NotchViewModel`, `NotchView`, `NotchWindow`, and `AppDelegate` must be **preserved without modification**. The only structural change is replacing `NotchCompositeView`'s multi-case switch with a single `TodoPlaceholderView`, and reducing `GalleryModel` / `GalleryItem` to a single `.todo` case.

The phase has two surgical edit points and one new file:
1. **Edit** `GalleryModel.swift` — replace the 9-case `GalleryItem` enum with a single `.todo` case.
2. **Edit** `NotchCompositeView.swift` — remove all case branches and render a simple `TodoPlaceholderView`.
3. **Create** `TodoItem.swift` — Codable struct with required fields.

All three changes are small and low-risk. The largest risk is `NotchCompositeView` retaining import references to now-deleted view types (e.g. `TimerMenuView`, `TrayView`). The safest approach is to delete or gut the referenced view source files while keeping their type names as empty stubs, or to remove the imports entirely.

**Primary recommendation:** Edit in-place; do not restructure directories. Register `TodoItem.swift` via xcodeproj gem immediately after creating it.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift | 5.x (Xcode 16) | Language | Already in project |
| SwiftUI | macOS 14+ | UI framework | Already in project |
| Foundation | OS-bundled | Codable, UUID, Date | Part of Apple SDK |
| xcodeproj (Ruby gem) | 1.27.0 | Register new .swift files in .xcodeproj without Xcode GUI | Required by project constraints |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| xcodebuild | Xcode 16 CLI | Build verification after each change | After every file edit/add |
| ColorfulX | (existing SPM dep) | Already imported by NotchCompositeView | Keep import; remove only the case references |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| xcodeproj gem | Direct project.pbxproj edit | pbxproj editing is fragile, merge-conflict-prone; xcodeproj gem is the standard |
| TodoPlaceholderView stub | Real TodoView | TodoView is Phase 2; Phase 1 only needs a compile-clean placeholder |

**Installation:**
```bash
gem install xcodeproj
```

**Version verification:**
```bash
gem list xcodeproj
# xcodeproj (1.27.0) or newer is fine
```

---

## Architecture Patterns

### Peninsula Source Layout (relevant to Phase 1)

```
Peninsula/
├── AppDelegate.swift              # Window lifecycle — DO NOT TOUCH
├── Notch/
│   ├── NotchView.swift            # Hover detection + NotchHoverView — DO NOT TOUCH
│   ├── NotchViewModel.swift       # Animation state machine — DO NOT TOUCH
│   ├── NotchViewModel+Events.swift # Haptics setup — DO NOT TOUCH
│   ├── NotchViewModels.swift      # Singleton array — DO NOT TOUCH
│   ├── NotchWindow.swift          # NSPanel setup — DO NOT TOUCH
│   ├── NotchWindowController.swift # Window controller — DO NOT TOUCH
│   ├── NotchModel.swift           # Keyboard-triggered state — DO NOT TOUCH
│   ├── Gallery/
│   │   └── GalleryModel.swift     # EDIT: gut to single .todo case
│   ├── Notch/
│   │   ├── NotchCompositeView.swift # EDIT: replace switch with TodoPlaceholderView
│   │   ├── NotchNavView.swift     # Navigation pill — can keep or stub
│   │   ├── NotchBackgroundView.swift # Background shape — DO NOT TOUCH
│   │   └── NotchContentType.swift # May become redundant — stub or delete
│   ├── Apps/
│   │   ├── AppsView.swift         # Stub or keep (no longer referenced)
│   │   └── AppsViewModel.swift    # Remove from GalleryModel init
│   └── Template/
│       └── HeaderView.swift       # Keep — used by NotchCompositeView
└── Todo/                          # NEW directory
    └── TodoItem.swift             # NEW Codable struct (STORE-02)
```

### Pattern 1: Gutting GalleryItem to a Single Case

**What:** Replace the 9-case enum with exactly 1 case (`.todo`), adjust `count()` and `toTitle()`, remove `next()`/`previous()` navigation since there's only one item.

**When to use:** When stripping a multi-tab gallery to a single slot.

**Example:**
```swift
// Source: inferred from GalleryModel.swift structure at github.com/Celve/Peninsula
enum GalleryItem: Int, Codable, Hashable, Equatable {
    case todo

    func count() -> Int { 1 }
    func toTitle() -> String { "Todo" }
}

class GalleryModel: ObservableObject {
    static let shared = GalleryModel()
    @Published var currentItem: GalleryItem = .todo
}
```

### Pattern 2: Replacing NotchCompositeView Switch

**What:** Replace the 9-branch switch in the body with a single `TodoPlaceholderView`. Keep `HeaderView` in place.

**Example:**
```swift
// Source: derived from NotchCompositeView.swift at github.com/Celve/Peninsula
struct NotchCompositeView: View {
    @StateObject var vm: NotchViewModel
    @ObservedObject var galleryModel = GalleryModel.shared

    var headline: some View {
        Text("Todo").contentTransition(.numericText())
    }

    var menubar: some View { EmptyView() }

    var body: some View {
        VStack(alignment: .center, spacing: vm.spacing) {
            HeaderView(headline: headline, menubar: menubar)
                .animation(vm.normalAnimation, value: galleryModel.currentItem)
            TodoPlaceholderView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .transition(.blurReplace)
    }
}

struct TodoPlaceholderView: View {
    var body: some View {
        Text("Todo coming soon")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

### Pattern 3: Codable TodoItem with Priority Enum

**What:** Swift struct conforming to `Codable`, `Identifiable` for use in SwiftUI `List`.

**Example:**
```swift
// Source: Swift Foundation docs — Codable, UUID, Date
import Foundation

enum Priority: String, Codable, CaseIterable {
    case high
    case normal
    case low
}

struct TodoItem: Identifiable, Codable {
    var id: UUID
    var title: String
    var priority: Priority
    var isDone: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        priority: Priority = .normal,
        isDone: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.priority = priority
        self.isDone = isDone
        self.createdAt = createdAt
    }
}
```

### Pattern 4: Registering a New Swift File via xcodeproj Gem

**What:** After creating `TodoItem.swift` on disk, run a Ruby script to add it to the Xcode project target.

**Example:**
```ruby
# Source: https://gist.github.com/larryaasen/5035313 + xcodeproj 1.27 docs
require 'xcodeproj'

project_path = 'Peninsula.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'Peninsula' }

# Find or create the Todo group
main_group = project.main_group['Peninsula']
todo_group = main_group['Todo'] || main_group.new_group('Todo', 'Peninsula/Todo')

file_ref = todo_group.new_file('TodoItem.swift')
target.source_build_phase.add_file_reference(file_ref)

project.save
```

Run with:
```bash
ruby add_todo_files.rb
```

### Anti-Patterns to Avoid

- **Deleting source files without stubbing:** If you delete `TimerMenuView.swift` but `NotchCompositeView.swift` still imports it, the build fails. Either stub the types or fully remove the import/reference first.
- **Creating Swift files without xcodeproj registration:** A `.swift` file on disk not added to the `.xcodeproj` compiles silently to nothing — xcodebuild will report "file not found" for any types it defines.
- **Touching NotchViewModel.swift:** The animation state machine is the heart of the notch behavior. Any change here risks breaking NOTCH-01/NOTCH-02.
- **Removing `@ObservedObject var galleryModel = GalleryModel.shared` from NotchCompositeView:** It is used for reactive header updates. Keep the binding even if the body content is replaced.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Notch expand/collapse animation | Custom NSAnimation or CAAnimation | Peninsula's existing `notchPop()` / `notchClose()` in `NotchViewModel` | Spring curves, timing, and hover rect math are already proven |
| Hover detection | Global mouse tracking | Peninsula's `reevaluateHover()` in `NotchHoverView` | Already handles edge cases: resize, abstractSize changes, keyboard override |
| Window management | Custom NSWindow subclass | Peninsula's `NotchWindow` + `NotchWindowController` | Handles `.accessory` policy, screen placement, always-on-top |
| Codable persistence | Custom encoder/decoder | `JSONEncoder` + `JSONDecoder` + `UserDefaults` | Standard pattern; TodoItem already conforms to Codable |
| Xcode project file editing | Manual pbxproj hex editing | xcodeproj Ruby gem | pbxproj is not human-editable safely |

**Key insight:** Phase 1 is almost entirely preservation work. The value is in what you *don't* change.

---

## Common Pitfalls

### Pitfall 1: Stranded type references after gutting the switch

**What goes wrong:** After removing cases from `NotchCompositeView`, the compiler complains about unresolved `TimerMenuView`, `TrayView`, `AppsView`, etc.
**Why it happens:** Swift needs all referenced types to exist at compile time, even if never instantiated.
**How to avoid:** Either (a) keep the source files as empty stubs, or (b) remove all gallery view source files AND their references from `NotchCompositeView` in the same edit.
**Warning signs:** `xcodebuild` error "cannot find type 'TimerMenuView' in scope"

### Pitfall 2: AppsViewModel still initialized in GalleryModel

**What goes wrong:** `GalleryModel` contains `let appsViewModel: AppsViewModel = AppsViewModel()`. After removing `AppsView`, `AppsViewModel` reference may cause a build error if `AppsViewModel.swift` is also removed.
**Why it happens:** The existing GalleryModel instantiates AppsViewModel unconditionally.
**How to avoid:** Remove the `appsViewModel` property from `GalleryModel` at the same time as removing `.apps` from the enum.
**Warning signs:** "Cannot find type 'AppsViewModel'" during build

### Pitfall 3: New .swift file not registered in .xcodeproj

**What goes wrong:** `TodoItem.swift` exists on disk but the compiler never sees it; types are missing.
**Why it happens:** Xcode projects maintain an explicit file manifest in `project.pbxproj` — unlike many build systems, files on disk are not automatically compiled.
**How to avoid:** Run the xcodeproj Ruby script immediately after `Write`-ing the new file. Verify with `xcodebuild build` before proceeding.
**Warning signs:** "Cannot find type 'TodoItem' in scope" despite the file existing

### Pitfall 4: NotchNavView still references old GalleryItem cases

**What goes wrong:** `NotchNavView` renders nav buttons for `.apps`, `.timer`, `.tray`, `.notification`, `.settings`. After gutting GalleryItem, these case references break.
**Why it happens:** NotchNavView is tightly coupled to the gallery item list.
**How to avoid:** Either delete/stub `NotchNavView`, or replace its body with `EmptyView()`. The `.popping` state in `NotchView` renders `NotchNavView` — since Phase 1 only needs hover-to-open, disabling the pop nav is acceptable.
**Warning signs:** Compiler errors in `NotchNavView.swift` referencing nonexistent enum cases

### Pitfall 5: Signing/entitlement issues after build target modification

**What goes wrong:** Adding a new file or group in a way that disrupts the target membership breaks code signing.
**Why it happens:** xcodeproj gem must add the file to the correct target (`Peninsula`, not a test target).
**How to avoid:** Always `target.source_build_phase.add_file_reference(file_ref)` against the main `Peninsula` target found by name, not `targets.first` which could be wrong.
**Warning signs:** `xcodebuild` error "Code signing is required for product type..."

---

## Code Examples

### Build verification command (Confidence: HIGH)
```bash
# From the repo root where Peninsula.xcodeproj lives
xcodebuild -project Peninsula.xcodeproj \
           -scheme Peninsula \
           -configuration Debug \
           build \
           CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO \
           | grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED"
```

### xcodeproj gem — open project safely (Confidence: HIGH)
```ruby
require 'xcodeproj'
project = Xcodeproj::Project.open('Peninsula.xcodeproj')
target  = project.targets.find { |t| t.name == 'Peninsula' }
```

### UserDefaults encode/decode array of Codable (Confidence: HIGH)
```swift
// Encode and save
let encoded = try? JSONEncoder().encode(items)
UserDefaults.standard.set(encoded, forKey: "todoItems")

// Load and decode
if let data = UserDefaults.standard.data(forKey: "todoItems"),
   let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
    self.items = decoded
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Xcodeproj::Project.new() | Xcodeproj::Project.open() | xcodeproj 1.x | `.new()` creates a blank project; `.open()` reads existing one |
| Manually editing project.pbxproj | xcodeproj gem | Standard since ~2013 | Safer, structured API |
| NSCoding for UserDefaults persistence | Codable + JSONEncoder | Swift 4 (2017) | No boilerplate; fully Swift-native |

**Deprecated/outdated:**
- `NSCoding` conformance for model types: replaced by `Codable` — do not use NSCoding for TodoItem.
- `Xcodeproj::Project.new()` to open existing projects: use `Xcodeproj::Project.open()` instead.

---

## Open Questions

1. **Does the forked repo already exist on disk, or does it need to be cloned?**
   - What we know: The project directory contains only `.git` and `.planning` — no source files yet.
   - What's unclear: The planning phase assumes a Peninsula fork already exists; it may need to be cloned/forked first.
   - Recommendation: The planner's Wave 0 task should be "clone/fork Peninsula into the project root" before any editing tasks.

2. **Does NotchNavView need to be kept for the .popping state?**
   - What we know: `NotchView.swift` renders `NotchNavView` when `status == .popping`. The popping state is triggered by hover entry (`notchPop()` is called before `notchOpen()`).
   - What's unclear: Whether gutting NotchNavView's body (to EmptyView) breaks the popping animation visually.
   - Recommendation: Stub `NotchNavView` to `EmptyView` for Phase 1; the notch will still animate correctly because `notchPop()` just changes the status enum — the visual nav buttons can be absent.

3. **Which gallery source subdirectories (Timer/, Tray/, Notification/, Switch/) can be safely deleted vs. stubbed?**
   - What we know: `NotchCompositeView` references their view types. Removing files without removing references breaks the build.
   - What's unclear: Some types may be referenced from other files not examined (e.g. keyboard event handlers in NotchModel+Events may reference SwitchContentView).
   - Recommendation: Stub, don't delete, in Phase 1. Replace each referenced view body with `var body: some View { EmptyView() }`. Full deletion is a cleanup task for after all tests pass.

---

## Validation Architecture

> nyquist_validation is explicitly set to false in .planning/config.json — this section is skipped.

---

## Sources

### Primary (HIGH confidence)
- `github.com/Celve/Peninsula` raw source files — NotchViewModel.swift, NotchView.swift, NotchCompositeView.swift, GalleryModel.swift, NotchContentType.swift, NotchNavView.swift fetched directly via raw.githubusercontent.com
- [xcodeproj gem gist (larryaasen)](https://gist.github.com/larryaasen/5035313) — xcodeproj Ruby API patterns
- [RubyDoc xcodeproj 1.27.0](https://www.rubydoc.info/gems/xcodeproj/) — current gem version and API reference
- [Apple Xcode project pbxproj](https://github.com/Celve/Peninsula/blob/main/Peninsula.xcodeproj/project.pbxproj) — scheme name "Peninsula", target name "Peninsula", deployment target macOS 14.0

### Secondary (MEDIUM confidence)
- [HackingWithSwift Codable + UserDefaults](https://www.hackingwithswift.com/example-code/system/how-to-load-and-save-a-struct-in-userdefaults-using-codable) — encode/decode pattern for arrays
- [Apple TN2339 xcodebuild FAQ](https://developer.apple.com/library/archive/technotes/tn2339/_index.html) — xcodebuild command reference

### Tertiary (LOW confidence)
- None — all findings verified against source code or official documentation.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified against live Peninsula source and gem docs
- Architecture: HIGH — derived directly from fetched source files
- Pitfalls: HIGH — inferred from direct code inspection (type references, registration model)

**Research date:** 2026-03-17
**Valid until:** 2026-04-17 (Peninsula is stable; SwiftUI/xcodeproj APIs are stable)
