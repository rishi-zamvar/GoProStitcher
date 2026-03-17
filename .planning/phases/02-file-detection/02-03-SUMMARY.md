---
phase: 02-file-detection
plan: 03
subsystem: ui
tags: [swiftui, tca, composable-architecture, nspanel, folder-picker, macos]

# Dependency graph
requires:
  - phase: 02-file-detection/02-01
    provides: GoProNameParser (GH/GX naming regex, sort key logic)
  - phase: 02-file-detection/02-02
    provides: FolderScanner.scan(url:) returning FolderScanResult with ScannedChunk array
provides:
  - FolderPickerFeature TCA @Reducer wiring NSOpenPanel to FolderScanner
  - FolderPickerView SwiftUI view with success/empty/noGoProFiles/loading states
  - ContentView updated to mount FolderPickerView with a TCA Store
  - Full DETECT-01 through DETECT-04 user flow working end-to-end
affects: [03-review-screen, 04-stitching]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "TCA @Reducer with @ObservableState for SwiftUI state management"
    - "NSOpenPanel run via .run { } + MainActor.run { } to satisfy main-thread requirement without blocking TCA reducer"
    - "userCancelledPicker action preserves prior scanResult on cancel (no flicker)"
    - "@Bindable var store: StoreOf<Feature> for TCA 1.x @ObservableState views"

key-files:
  created:
    - GoProStitcher/Features/FolderPicker/FolderPickerFeature.swift
    - GoProStitcher/Features/FolderPicker/FolderPickerView.swift
  modified:
    - GoProStitcher/ContentView.swift
    - GoProStitcher.xcodeproj/project.pbxproj

key-decisions:
  - "userCancelledPicker is a distinct action (not scanCompleted(.empty)) so cancel preserves prior scan result"
  - "NSOpenPanel.runModal() called inside MainActor.run inside .run effect — satisfies AppKit main-thread rule without blocking reducer"
  - "FolderPickerView shows MB with 1 decimal place using sum of sizeBytes / 1_048_576"

patterns-established:
  - "TCA Feature pattern: one file per feature (Feature.swift), one file per view (View.swift) under Features/FeatureName/"
  - "NSOpenPanel in TCA: always wrap runModal() in MainActor.run inside a .run effect"

# Metrics
duration: ~45min
completed: 2026-03-17
---

# Phase 2 Plan 03: FolderPickerFeature Summary

**TCA FolderPickerFeature + SwiftUI FolderPickerView wired to FolderScanner via NSOpenPanel, completing the full DETECT-01 through DETECT-04 user flow**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-03-17
- **Completed:** 2026-03-17
- **Tasks:** 1 auto + 1 checkpoint (human-verify)
- **Files modified:** 4

## Accomplishments

- FolderPickerFeature TCA reducer handles selectFolderButtonTapped, folderSelected, scanCompleted, and userCancelledPicker actions with correct state transitions
- FolderPickerView displays loading state (ProgressView), success summary (file count + total MB), and distinct error messages for empty vs non-GoPro folders
- NSOpenPanel integrated via MainActor.run inside TCA .run effect — satisfies AppKit main-thread requirement without blocking the reducer
- ContentView updated to mount FolderPickerView with a full TCA Store, completing the Phase 2 UI surface
- User verification confirmed all 7 acceptance steps pass (open panel, empty folder, non-GoPro folder, GoPro files with count+size, cancel preserves state)

## Task Commits

1. **Task 1: Implement FolderPickerFeature TCA reducer + FolderPickerView** - `d54d3d5` (feat)

**Plan metadata:** _(to be recorded — docs commit follows)_

## Files Created/Modified

- `GoProStitcher/Features/FolderPicker/FolderPickerFeature.swift` - TCA @Reducer with @ObservableState; actions for selectFolderButtonTapped, folderSelected, scanCompleted, userCancelledPicker; calls FolderScanner.scan(url:)
- `GoProStitcher/Features/FolderPicker/FolderPickerView.swift` - SwiftUI view with Select Folder button, ProgressView loading overlay, success/empty/noGoProFiles result display
- `GoProStitcher/ContentView.swift` - Replaced placeholder with FolderPickerView(store: Store(...) { FolderPickerFeature() })
- `GoProStitcher.xcodeproj/project.pbxproj` - Added FolderPickerFeature.swift and FolderPickerView.swift as compile sources

## Decisions Made

- **userCancelledPicker is a distinct action** — using `.scanCompleted(.empty)` on cancel would overwrite a previously valid scan result; a dedicated cancel action only resets `isLoading` without touching `scanResult`.
- **NSOpenPanel via MainActor.run** — TCA effects run off the main actor; AppKit requires NSOpenPanel.runModal() on the main thread. Wrapping in `await MainActor.run { }` inside `.run` satisfies both constraints cleanly.
- **MB display with 1 decimal place** — total size in MB (sizeBytes / 1_048_576) formatted to 1 decimal gives a useful and human-readable summary for DETECT-04.

## Deviations from Plan

None — plan executed exactly as written. The `userCancelledPicker` action refinement was explicitly described in the plan's action notes (the plan itself called it out as the correct approach).

## Issues Encountered

None — build succeeded on first attempt, and user verification passed all 7 steps without requiring any fixes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All four DETECT requirements (DETECT-01 through DETECT-04) are complete and user-verified
- FolderPickerFeature.State holds a FolderScanResult with the array of ScannedChunk values — Phase 3 review screen can receive this state directly via TCA child store or parent reducer
- Phase 3 (review screen with reorder/preview) can build directly on top of the ScannedChunk array produced here
- No blockers identified

---
*Phase: 02-file-detection*
*Completed: 2026-03-17*
