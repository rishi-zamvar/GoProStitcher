---
phase: 06-audio-extraction-ui
plan: 01
subsystem: ui
tags: [tca, swiftui, avfoundation, nsopenpanel, nsworkspace, ffmpeg, mpeg4, mp3, perception]

# Dependency graph
requires:
  - phase: 05-audio-extractor-engine
    provides: AudioExtractor.extract + AudioExtractorError — the ffmpeg ffmpeg-backed extraction engine used by AudioExtractionFeature

provides:
  - AudioFilePickerFeature: TCA reducer for MP4 file selection via NSOpenPanel filtered to .mpeg4Movie
  - AudioExtractionFeature: TCA reducer managing extraction lifecycle, AVFoundation metadata load, AudioExtractor.extract call, NSWorkspace Finder reveal
  - AudioExtractionView + AudioFilePickerView: SwiftUI views for picker screen and extraction progress/completion screen
  - AppFeature: audioPicker Scope + audioExtraction optional state + showAudioPicker flag wired in
  - ContentView: full routing tree including audio screens
  - AudioExtractionPipelineTests: 2 integration tests (basic extraction, collision suffix)
affects: [07-home-screen]

# Tech tracking
tech-stack:
  added: [UniformTypeIdentifiers (.mpeg4Movie for NSOpenPanel content type filter)]
  patterns:
    - "@Perception.Bindable + WithPerceptionTracking for macOS 13 compatible TCA views"
    - "AudioFilePickerFeature pattern: NSOpenPanel via MainActor.run inside .run effect"
    - ".ifLet for optional child state (audioExtraction) — same pattern as chunkReview/stitchProgress"
    - "Scope for always-present child state (audioPicker) — same pattern as folderPicker"
    - "showAudioPicker Bool flag in AppFeature.State as thin Phase 6 navigation bridge (Phase 7 HomeFeature will replace)"
    - "Integration tests: ffmpeg lavfi sine+color to synthesize audio-bearing MP4 fixture at test time"

key-files:
  created:
    - GoProStitcher/Features/AudioExtraction/AudioFilePickerFeature.swift
    - GoProStitcher/Features/AudioExtraction/AudioExtractionFeature.swift
    - GoProStitcher/Features/AudioExtraction/AudioExtractionView.swift
    - GoProStitcherIntegrationTests/AudioExtractionPipelineTests.swift
  modified:
    - GoProStitcher/AppFeature.swift
    - GoProStitcher/ContentView.swift
    - GoProStitcher.xcodeproj/project.pbxproj

key-decisions:
  - "showAudioPicker Bool flag as minimal Phase 6 navigation bridge — Phase 7 HomeFeature will replace with proper tool routing"
  - "AVFoundation metadata (duration, file size, audio bitrate) loaded concurrently inside startExtraction .run effect — view shows metadata before extraction completes"
  - "AudioExtractionView + AudioFilePickerView colocated in one file (AudioExtractionView.swift) for cohesion"
  - "Extract Audio button placed in ContentView else branch (not inside FolderPickerView) to keep FolderPickerFeature unmodified"
  - "Integration test fixture synthesized at test time using ffmpeg lavfi sine + color — no static fixture file needed"

patterns-established:
  - "Tool flow pattern: showXxxTool Bool flag + Scope(state: \\.xxxPicker) + optional xxxExtraction state + .ifLet"
  - "ffmpeg lavfi fixture synthesis in integration tests for audio-bearing MP4s"

# Metrics
duration: 4min
completed: 2026-03-18
---

# Phase 6 Plan 01: Audio Extraction UI Summary

**Two TCA reducers (AudioFilePickerFeature + AudioExtractionFeature), SwiftUI picker and progress screens, wired into AppFeature/ContentView with NSWorkspace Finder reveal and 2 passing integration tests**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-18T13:19:11Z
- **Completed:** 2026-03-18T13:23:00Z
- **Tasks:** 2 auto tasks complete (checkpoint pending human verification)
- **Files modified:** 7

## Accomplishments

- AudioFilePickerFeature opens NSOpenPanel filtered to `.mpeg4Movie` using UniformTypeIdentifiers
- AudioExtractionFeature loads AVFoundation metadata (duration, file size, audio bitrate) concurrently, calls AudioExtractor.extract on background thread, reveals output in Finder via NSWorkspace
- AudioExtractionView displays metadata card + indeterminate linear spinner during extraction, green checkmark on completion, red X on error
- AppFeature wires both audio reducers alongside the existing stitch flow with zero disruption to prior features
- ContentView routes audio screens at highest priority; adds "Extract Audio from MP4" button to home screen
- Both AudioExtractionPipelineTests pass: basic MP3 extraction and collision-suffix behavior

## Task Commits

1. **Task 1: AudioFilePickerFeature + AudioExtractionFeature + AudioExtractionView** - `be2f619` (feat)
2. **Task 2: Wire into AppFeature + ContentView + Integration Test** - `bfc69f4` (feat)

## Files Created/Modified

- `GoProStitcher/Features/AudioExtraction/AudioFilePickerFeature.swift` - NSOpenPanel picker reducer for single MP4 file selection
- `GoProStitcher/Features/AudioExtraction/AudioExtractionFeature.swift` - Extraction lifecycle: metadata load, AudioExtractor.extract, Finder reveal
- `GoProStitcher/Features/AudioExtraction/AudioExtractionView.swift` - AudioFilePickerView + AudioExtractionView (picker screen + progress/completion screen)
- `GoProStitcher/AppFeature.swift` - Added audioPicker Scope, audioExtraction .ifLet, showAudioPicker flag, related action handlers
- `GoProStitcher/ContentView.swift` - Full routing tree with audio screens + "Extract Audio from MP4" entry button
- `GoProStitcherIntegrationTests/AudioExtractionPipelineTests.swift` - 2 integration tests using ffmpeg lavfi fixture synthesis
- `GoProStitcher.xcodeproj/project.pbxproj` - Updated via xcodegen to include new sources

## Decisions Made

- `showAudioPicker` Bool flag added to AppFeature.State as a minimal Phase 6 bridge; Phase 7 HomeFeature will replace it with proper tool routing from a home screen
- AVFoundation metadata loaded inside the `startExtraction` `.run` effect so the view can display duration/size/bitrate before extraction finishes
- "Extract Audio from MP4" button placed directly in ContentView's else branch to keep FolderPickerFeature unmodified — clean seam for Phase 7

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Audio extraction tool is fully functional and wired into the app
- Phase 7 (Home Screen) can replace the `showAudioPicker` Bool + the bottom button with a HomeFeature that routes to both tools from a launcher screen
- All integration tests pass; no blockers

---
*Phase: 06-audio-extraction-ui*
*Completed: 2026-03-18*
