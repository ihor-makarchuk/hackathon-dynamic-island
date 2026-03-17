---
phase: 01-shell
plan: 01
subsystem: ui
tags: [swift, swiftui, xcode, macos, peninsula, swiftpm]

# Dependency graph
requires: []
provides:
  - Peninsula fork with single .todo GalleryItem (notch expand/collapse animation intact)
  - TodoPlaceholderView replacing multi-case gallery switch in NotchCompositeView
  - TodoItem Codable struct (id, title, priority, isDone, createdAt) in Peninsula/Todo/
  - Compilable Peninsula project building clean via xcodebuild
affects: [02-todo-ui, 02-persistence]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "PBXFileSystemSynchronizedRootGroup: Peninsula uses Xcode 16 filesystem-synced groups — new Swift files in Peninsula/ are auto-discovered without manual xcodeproj registration"
    - "GalleryModel.shared: single @Published currentItem: GalleryItem = .todo for reactive header binding"
    - "TodoPlaceholderView: stub View in NotchCompositeView replacing multi-case switch — replace with real TodoView in Phase 2"

key-files:
  created:
    - Peninsula/Todo/TodoItem.swift
  modified:
    - Peninsula/Notch/Gallery/GalleryModel.swift
    - Peninsula/Notch/Notch/NotchCompositeView.swift
    - Peninsula/Notch/Notch/NotchNavView.swift
    - Peninsula/Notch/NotchViewModel.swift
    - Peninsula/Notch/NotchView.swift
    - Peninsula/Notch/Notch/NotchBackgroundView.swift
    - Peninsula/Notch/NotchModel+Events.swift
    - Peninsula/Notch/Live/DockModel.swift
    - Peninsula/Notch/Switch/SwtichMenubarView.swift
    - Peninsula/Notch/Timer/TimerView.swift
    - Peninsula/Notch/Tray/TrayDropMenubarView.swift

key-decisions:
  - "Xcode 16 PBXFileSystemSynchronizedRootGroup auto-discovers Peninsula/Todo/TodoItem.swift — no xcodeproj gem registration needed"
  - "GalleryItem.next() method removed entirely since only one item exists — NotchBackgroundView tap gesture becomes no-op"
  - "Rule 3 auto-fixes applied to NotchViewModel, NotchView, and other files referencing removed GalleryItem cases (.apps, .timer, .tray, etc.) — replaced with .todo or EmptyView stubs"

patterns-established:
  - "Pattern 1: Single-case GalleryItem — GalleryModel.shared always returns .todo; no navigation needed"
  - "Pattern 2: TodoPlaceholderView in NotchCompositeView — replace body in Phase 2 with real TodoView"
  - "Pattern 3: Filesystem-synced Xcode group — create files in Peninsula/ subdirs, no registration script needed"

requirements-completed: [NOTCH-01, NOTCH-02, NOTCH-03, STORE-02]

# Metrics
duration: 7min
completed: 2026-03-17
---

# Phase 1 Plan 1: Shell Summary

**Peninsula forked and stripped to a single .todo notch slot with TodoItem Codable struct — hover/collapse animation intact, xcodebuild succeeds clean**

## Performance

- **Duration:** 7 min
- **Started:** 2026-03-17T21:43:13Z
- **Completed:** 2026-03-17T21:50:36Z
- **Tasks:** 3
- **Files modified:** 12 (11 edited + 1 created)

## Accomplishments
- Cloned Peninsula into project root; baseline build verified before any changes
- Gutted GalleryItem enum from 9 cases to single `.todo` case; removed navigation methods and AppsViewModel property
- NotchCompositeView now renders TodoPlaceholderView instead of multi-case switch; hover/animation machinery untouched
- TodoItem Codable struct created with all required fields: id (UUID), title (String), priority (Priority), isDone (Bool), createdAt (Date)
- Full project builds clean via xcodebuild with no errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Clone Peninsula and verify baseline build** - `9f6541e` (chore)
2. **Task 2: Gut gallery to single .todo case and stub removed views** - `a0b2311` (feat)
3. **Task 3: Create TodoItem.swift Codable struct and register in Xcode project** - `1341813` (feat)

## Files Created/Modified
- `Peninsula/Todo/TodoItem.swift` - New Codable TodoItem struct with Priority enum; auto-discovered by Xcode 16 filesystem-synced group
- `Peninsula/Notch/Gallery/GalleryModel.swift` - Reduced to single `.todo` GalleryItem case; removed AppsViewModel, next(), previous()
- `Peninsula/Notch/Notch/NotchCompositeView.swift` - Replaced multi-case switch with TodoPlaceholderView; kept GalleryModel.shared binding
- `Peninsula/Notch/Notch/NotchNavView.swift` - Body stubbed to EmptyView (no navigation needed with single item)
- `Peninsula/Notch/NotchViewModel.swift` - Simplified notchOpenedSize (removed .switching/.searching cases); simplified header property
- `Peninsula/Notch/NotchView.swift` - Updated 2 galleryItem references from .apps/.tray to .todo
- `Peninsula/Notch/Notch/NotchBackgroundView.swift` - Replaced galleryModel.next() tap gesture with no-op
- `Peninsula/Notch/NotchModel+Events.swift` - Updated .searching/.switching references to .todo
- `Peninsula/Notch/Live/DockModel.swift` - Updated .notification reference to .todo
- `Peninsula/Notch/Switch/SwtichMenubarView.swift` - Stubbed body to EmptyView (removed .switchSettings reference)
- `Peninsula/Notch/Timer/TimerView.swift` - Updated .timer reference to .todo in TimerAbstractInstance.action
- `Peninsula/Notch/Tray/TrayDropMenubarView.swift` - Stubbed body to EmptyView (removed .traySettings reference)

## Decisions Made
- Used Xcode 16's PBXFileSystemSynchronizedRootGroup behavior — files in Peninsula/ subdirs are auto-discovered, no xcodeproj gem registration needed (the gem script failed with NoMethodError on the synchronized group type)
- Removed GalleryItem.next() from GalleryModel instead of keeping it as no-op — cleaner, and NotchBackgroundView tap gesture becomes an explicit no-op comment

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed all GalleryItem case references across 7 files**
- **Found during:** Task 2 (gut gallery step)
- **Issue:** Removing GalleryItem cases (.apps, .timer, .tray, .traySettings, .notification, .settings, .switching, .searching, .switchSettings) left stranded references in NotchViewModel, NotchView, NotchBackgroundView, NotchModel+Events, DockModel, SwtichMenubarView, TimerView, TrayDropMenubarView
- **Fix:** Replaced removed case references with .todo (for action closures) or EmptyView() (for view bodies); removed switch cases that had only a default branch remaining
- **Files modified:** Peninsula/Notch/NotchViewModel.swift, Peninsula/Notch/NotchView.swift, Peninsula/Notch/Notch/NotchBackgroundView.swift, Peninsula/Notch/NotchModel+Events.swift, Peninsula/Notch/Live/DockModel.swift, Peninsula/Notch/Switch/SwtichMenubarView.swift, Peninsula/Notch/Timer/TimerView.swift, Peninsula/Notch/Tray/TrayDropMenubarView.swift
- **Verification:** xcodebuild BUILD SUCCEEDED after all fixes
- **Committed in:** a0b2311 (Task 2 commit)

**2. [Rule 3 - Blocking] xcodeproj gem registration script failed on PBXFileSystemSynchronizedRootGroup**
- **Found during:** Task 3 (Xcode project registration)
- **Issue:** Plan assumed traditional PBXGroup structure. Peninsula uses Xcode 16's PBXFileSystemSynchronizedRootGroup which does NOT support the `[]` subscript method — ruby script raised NoMethodError
- **Fix:** Discovered that PBXFileSystemSynchronizedRootGroup auto-discovers files on disk; xcodebuild confirmed "Compiling TodoItem.swift" without manual registration. add_todo_files.rb deleted as planned.
- **Files modified:** None (registration not needed)
- **Verification:** xcodebuild output shows "SwiftCompile ... Compiling TodoItem.swift" + BUILD SUCCEEDED
- **Committed in:** 1341813 (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 3 - blocking)
**Impact on plan:** Both auto-fixes necessary to unblock compilation. The GalleryItem reference cascade was anticipated by the research (Pitfall 1-2); the synchronized group behavior was a discovery that simplified registration (no script needed).

## Issues Encountered
- Peninsula uses Xcode 16's filesystem-synchronized groups instead of traditional PBXGroup — research assumed the old group model. The actual behavior is simpler: files just need to exist on disk.

## User Setup Required
None - no external service configuration required.

## Self-Check: PASSED

- Peninsula/Todo/TodoItem.swift: FOUND
- Peninsula/Notch/Gallery/GalleryModel.swift: FOUND
- Peninsula/Notch/Notch/NotchCompositeView.swift: FOUND
- .planning/phases/01-shell/01-01-SUMMARY.md: FOUND
- Commits 9f6541e, a0b2311, 1341813: FOUND
- xcodebuild BUILD SUCCEEDED: CONFIRMED

## Next Phase Readiness
- Phase 2 can start immediately: replace TodoPlaceholderView in NotchCompositeView.swift with real TodoView
- GalleryModel.shared is wired up and reactive
- TodoItem.swift provides the data model for UserDefaults persistence
- Build is clean and all animation/hover machinery (NotchViewModel, NotchView, NotchWindow) works as-is
