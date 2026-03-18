---
phase: 07-home-screen-app-rename
plan: 01
subsystem: ui
tags: [swiftui, tca, composable-architecture, macos, navigation, xcodegen]

# Dependency graph
requires:
  - phase: 06-audio-extraction-ui
    provides: AudioExtractionView, AudioFilePickerFeature, AudioExtractionFeature wired to AppFeature
  - phase: 05-audio-extractor-engine
    provides: AudioExtractor engine and GoProStitcherKit package
provides:
  - HomeFeature reducer with stitchVideoTapped / extractAudioTapped actions
  - HomeView with extensible ToolDescriptor array and two tool buttons
  - AppFeature with ActiveTool enum routing (replaces showAudioPicker Bool)
  - ContentView switching on activeTool driving home / stitch / audio sub-trees
  - backToHome action resetting all sub-state
  - CFBundleDisplayName updated to "GoPro Toolkit" in project.yml and Info.plist
affects: [future tool phases that add entries to ToolDescriptor array]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - ToolDescriptor array for extensible home-screen tool buttons
    - Enum-based top-level navigation (ActiveTool) replacing Bool flags
    - Parent-store HomeView pattern (takes StoreOf<AppFeature>, sends top-level actions)
    - backToHome action resets all sub-state to initial values

key-files:
  created:
    - GoProStitcher/Features/Home/HomeFeature.swift
    - GoProStitcher/Features/Home/HomeView.swift
  modified:
    - GoProStitcher/AppFeature.swift
    - GoProStitcher/ContentView.swift
    - GoProStitcher/Features/StitchProgress/StitchProgressView.swift
    - project.yml
    - GoProStitcher/Info.plist
    - GoProStitcher.xcodeproj (regenerated)

key-decisions:
  - "HomeView takes StoreOf<AppFeature> (not StoreOf<HomeFeature>) so it can dispatch top-level navigation actions directly"
  - "ToolDescriptor array makes adding a third tool a single array entry"
  - "ActiveTool enum (not Bool flags) cleanly expresses mutually exclusive tool activation"
  - "backToHome resets audioPicker and folderPicker to fresh State() to avoid stale sub-state"

patterns-established:
  - "ToolDescriptor: extensible struct (title, subtitle, systemImage, action) for home-screen entries"
  - "ActiveTool enum pattern: enum ActiveTool: Equatable { case stitch, audio } with activeTool: ActiveTool? = nil"
  - "ContentView switches on store.activeTool with WithPerceptionTracking wrapper"

# Metrics
duration: 8min
completed: 2026-03-18
---

# Phase 7 Plan 01: Home Screen & App Rename Summary

**HomeFeature + HomeView with enum-based ActiveTool routing in AppFeature; app display name changed to "GoPro Toolkit"; both tool flows navigate back to home screen**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-18T13:42:47Z
- **Completed:** 2026-03-18T13:50:00Z
- **Tasks:** 2 auto tasks complete (checkpoint pending human verify)
- **Files modified:** 8

## Accomplishments
- App display name changed from "GoProStitcher" to "GoPro Toolkit" in project.yml, Info.plist, and StitchProgressView title
- HomeFeature reducer and HomeView created with extensible ToolDescriptor approach
- AppFeature refactored from Bool flag to ActiveTool enum navigation with backToHome action
- ContentView switches on activeTool routing to HomeView, stitch flow, or audio flow
- Back navigation added to stitch folder-picker screen; audio cancel returns to home
- xcodegen regenerated and BUILD SUCCEEDED

## Task Commits

Each task was committed atomically:

1. **Task 1: Rename display name and create HomeFeature + HomeView** - `a136782` (feat)
2. **Task 2: Refactor AppFeature routing, update ContentView, regenerate project** - `31c35e6` (feat)

_Note: Checkpoint (Task 3) is human-verify — no commit until after approval._

## Files Created/Modified
- `GoProStitcher/Features/Home/HomeFeature.swift` - Simple reducer with stitchVideoTapped / extractAudioTapped; navigation delegated to AppFeature
- `GoProStitcher/Features/Home/HomeView.swift` - Two-button home screen built from ToolDescriptor array; takes StoreOf<AppFeature>
- `GoProStitcher/AppFeature.swift` - ActiveTool enum, home child reducer scope, backToHome action, audioPicker cancel returns home
- `GoProStitcher/ContentView.swift` - Switches on store.activeTool inside WithPerceptionTracking
- `GoProStitcher/Features/StitchProgress/StitchProgressView.swift` - "GoProStitcher" title updated to "GoPro Toolkit"
- `project.yml` - CFBundleDisplayName: GoPro Toolkit
- `GoProStitcher/Info.plist` - CFBundleDisplayName: GoPro Toolkit
- `GoProStitcher.xcodeproj` - Regenerated via xcodegen

## Decisions Made
- HomeView takes StoreOf<AppFeature> directly (not a scoped HomeFeature store) so it can dispatch top-level navigation without an extra Scope or delegate action
- ToolDescriptor array makes adding future tools a one-line change
- backToHome resets both audioPicker and folderPicker to fresh State() to avoid stale sub-state on re-entry

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Both auto tasks committed and BUILD SUCCEEDED
- Awaiting human verification (Task 3 checkpoint): launch app, confirm home screen, test both tool flows, confirm back navigation works

---
*Phase: 07-home-screen-app-rename*
*Completed: 2026-03-18*
