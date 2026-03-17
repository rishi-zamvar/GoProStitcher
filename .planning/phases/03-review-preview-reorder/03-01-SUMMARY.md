---
phase: 03-review-preview-reorder
plan: 01
subsystem: testing
tags: [avfoundation, swift, spm, tdd, metadata, thumbnail, mp4]

# Dependency graph
requires:
  - phase: 01-testing-infrastructure
    provides: TempDirectoryHelper, GoProFileFactory test helpers
  - phase: 02-file-detection
    provides: FolderScanner, ScannedChunk types; caseless enum pattern established

provides:
  - Public caseless enum AVMetadataReader in GoProStitcherKit
  - duration(url:) async -> TimeInterval? using AVURLAsset load(.duration)
  - resolution(url:) async -> CGSize? using loadTracks + load(.naturalSize)
  - thumbnail(url:) async -> NSImage? using AVAssetImageGenerator
  - Tiny valid MP4 fixture (GH010001.MP4) bundled with GoProStitcherKitTests

affects:
  - 03-02 (ChunkReviewFeature reducer calls AVMetadataReader for ORDER-04 metadata display)
  - 03-03 (thumbnail display in ORDER-01 chunk list)

# Tech tracking
tech-stack:
  added: [AVFoundation async API (macOS 13+), AppKit NSImage]
  patterns:
    - Caseless enum as pure static namespace (matches GoProNameParser, FolderScanner)
    - async/await AVFoundation: load(.duration), loadTracks(withMediaType:), load(.naturalSize)
    - AVAssetImageGenerator with appliesPreferredTrackTransform = true
    - SPM test target resources (Bundle.module for fixture lookup)

key-files:
  created:
    - GoProStitcherKit/Sources/GoProStitcherKit/AVMetadataReader.swift
    - GoProStitcherKit/Tests/GoProStitcherKitTests/AVMetadataReaderTests.swift
    - GoProStitcherKit/Tests/GoProStitcherKitTests/Resources/GH010001.MP4
  modified:
    - GoProStitcherKit/Package.swift

key-decisions:
  - "AVMetadataReader as caseless enum: matches existing pure-static-namespace pattern, prevents instantiation"
  - "Tiny real MP4 fixture generated with ffmpeg and committed to test Resources/: GoProFileFactory makes zero-filled files which AVFoundation cannot load"
  - "Bundle.module for fixture URL lookup: required for SPM test targets with bundled resources"
  - "copyCGImage(at:actualTime:) wrapped behind macOS 13 availability check: image(at:) async is macOS 13+, fallback for older builds"

patterns-established:
  - "SPM test resources: .copy('Resources') in Package.swift testTarget, access via Bundle.module.url(forResource:withExtension:)"
  - "AVFoundation async pattern: try? await asset.load(.) with guard nil checks before returning value"

# Metrics
duration: 8min
completed: 2026-03-18
---

# Phase 3 Plan 01: AVMetadataReader Summary

**AVFoundation async metadata reader (duration, resolution, first-frame thumbnail) as a caseless enum with 6 TDD tests, backed by a committed tiny MP4 fixture**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-03-17T22:09:49Z
- **Completed:** 2026-03-18T00:11:49Z
- **Tasks:** 2 (TDD RED + GREEN)
- **Files modified:** 4

## Accomplishments

- Public `AVMetadataReader` caseless enum with `duration`, `resolution`, and `thumbnail` async static functions
- All three functions gracefully return nil for non-existent or unreadable files — no crashes
- 6 TDD tests covering all branches (valid + invalid URL for each function) — all pass
- Real 1-second 160x90 H.264 MP4 fixture committed to test bundle; prior suite (34 tests) unaffected

## Task Commits

Each task committed atomically:

1. **Task 1: RED — failing AVMetadataReaderTests** - `b856360` (test)
2. **Task 2: GREEN — AVMetadataReader implementation** - `7936443` (feat)

**Plan metadata:** (see final commit below)

_Note: TDD tasks produced 2 commits (test RED → feat GREEN), no refactor needed_

## Files Created/Modified

- `GoProStitcherKit/Sources/GoProStitcherKit/AVMetadataReader.swift` - Public caseless enum, 3 async static AVFoundation functions
- `GoProStitcherKit/Tests/GoProStitcherKitTests/AVMetadataReaderTests.swift` - 6 async TDD tests (duration, resolution, thumbnail; valid + invalid URL each)
- `GoProStitcherKit/Tests/GoProStitcherKitTests/Resources/GH010001.MP4` - Tiny 1585-byte valid MP4 fixture (ffmpeg, 1s, 160x90, H.264)
- `GoProStitcherKit/Package.swift` - Added `.copy("Resources")` to testTarget

## Decisions Made

- **Caseless enum pattern:** Matches `GoProNameParser` and `FolderScanner` — pure static namespace, prevents instantiation
- **Real MP4 fixture required:** `GoProFileFactory.makeChunk` writes zero-filled bytes which AVFoundation cannot parse; created a tiny valid MP4 with ffmpeg and committed it to `Tests/GoProStitcherKitTests/Resources/`
- **Bundle.module lookup:** SPM test targets with `.copy("Resources")` must use `Bundle.module.url(forResource:withExtension:)` to locate bundled files
- **Async API only:** Used `asset.load(.duration)`, `asset.loadTracks(withMediaType:)`, `track.load(.naturalSize)` — no deprecated synchronous property accessors

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Created real MP4 fixture instead of GoProFileFactory zero-fill**

- **Found during:** Task 1 (RED — test setup)
- **Issue:** Plan stated "GoProFileFactory creates tiny valid MP4 fixtures" but GoProFileFactory.makeChunk writes zero-filled Data which AVFoundation cannot load — all "valid file" tests would have returned nil and passed for the wrong reason
- **Fix:** Generated a 1-second 160x90 H.264 MP4 with `ffmpeg -f lavfi`, committed it to `Tests/GoProStitcherKitTests/Resources/GH010001.MP4`, added `.copy("Resources")` to Package.swift, used `Bundle.module.url(forResource:withExtension:)` in setUp
- **Files modified:** GoProStitcherKit/Package.swift, Tests/GoProStitcherKitTests/Resources/GH010001.MP4
- **Verification:** All 6 AVMetadataReaderTests pass; duration > 0, resolution 160x90, thumbnail non-nil
- **Committed in:** b856360 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (missing critical — fixture must be real MP4 for AVFoundation)
**Impact on plan:** Auto-fix was essential for test correctness. No scope creep.

## Issues Encountered

None beyond the fixture discovery above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `AVMetadataReader` is ready for the `ChunkReviewFeature` reducer (Plan 03-02) to call on each `ScannedChunk.url`
- Thumbnail function returns `NSImage` — directly usable in SwiftUI via `Image(nsImage:)`
- Duration and resolution return simple value types — straightforward to store in TCA State
- No blockers

---
*Phase: 03-review-preview-reorder*
*Completed: 2026-03-18*
