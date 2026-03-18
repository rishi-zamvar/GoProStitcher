---
phase: 05-audioextractor-engine
plan: 01
subsystem: audio
tags: [swift, ffmpeg, spm, foundation-process, mp3, audio-extraction]

# Dependency graph
requires:
  - phase: 04-stitching-archive
    provides: ChunkStitcher pattern (caseless enum, Process, nullDevice I/O, ffmpeg path lookup)
provides:
  - AudioExtractorError enum (4 cases: ffmpegNotFound, inputNotFound, extractionFailed, outputWriteFailed)
  - AudioExtractor.extract(url:) -> URL (ffmpeg -vn -acodec libmp3lame -b:a 320k)
  - Collision-free output naming (stem.mp3 → stem_1.mp3 → stem_2.mp3, cap 999)
  - 6 unit tests covering all error/success/collision paths
  - GH010001_audio.MP4 fixture (1s h264+aac MP4 for extraction tests)
affects: [06-audioextractor-ui, 07-home-navigation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "caseless enum for stateless service (AudioExtractor follows ChunkStitcher pattern)"
    - "ffmpeg path probe via array-first lookup [/opt/homebrew, /usr/local, /usr/bin]"
    - "collision-free output: try stem.ext, then stem_N.ext up to N=999"
    - "Foundation.Process with nullDevice I/O for silent ffmpeg subprocess"

key-files:
  created:
    - GoProStitcherKit/Sources/GoProStitcherKit/AudioExtractorError.swift
    - GoProStitcherKit/Sources/GoProStitcherKit/AudioExtractor.swift
    - GoProStitcherKit/Tests/GoProStitcherKitTests/AudioExtractorTests.swift
    - GoProStitcherKit/Tests/GoProStitcherKitTests/Resources/GH010001_audio.MP4
  modified: []

key-decisions:
  - "ffmpeg args: [-y, -i, input, -vn, -acodec, libmp3lame, -b:a, 320k, output]"
  - "Output placed next to source file (same directory)"
  - "GH010001_audio.MP4 added as separate fixture from GH010001.MP4 — original is video-only and ffmpeg exits 234 when extracting audio from a stream-less file"

patterns-established:
  - "Audio fixture must have audio stream; video-only .MP4 causes ffmpeg exit 234 with -vn"

# Metrics
duration: 5min
completed: 2026-03-18
---

# Phase 5 Plan 01: AudioExtractor Engine Summary

**AudioExtractor.extract(url:) ships ffmpeg-backed 320kbps MP3 extraction with collision-free naming, error enum, and 6 unit tests all passing**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-18T13:02:23Z
- **Completed:** 2026-03-18T13:07:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- AudioExtractorError public enum with 4 cases and LocalizedError + Equatable conformance
- AudioExtractor.extract(url:) using ffmpeg `-vn -acodec libmp3lame -b:a 320k`, output placed next to source
- Collision-free output path (stem.mp3 → stem_1.mp3 → stem_2.mp3, capped at 999)
- 6 AudioExtractorTests: ffmpegNotFound (skipped on machines with ffmpeg), inputNotFound, collision_appendsSuffix, doubleCollision, successfulExtraction, outputNextToSource
- Added GH010001_audio.MP4 test fixture (1s h264+aac) to Resources

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement AudioExtractorError and AudioExtractor** - `b1faae8` (feat)
2. **Task 2: Write AudioExtractorTests** - `8ffd313` (test)

## Files Created/Modified
- `GoProStitcherKit/Sources/GoProStitcherKit/AudioExtractorError.swift` - Public error enum (4 cases, LocalizedError, Equatable)
- `GoProStitcherKit/Sources/GoProStitcherKit/AudioExtractor.swift` - Caseless enum with static extract(url:) → URL
- `GoProStitcherKit/Tests/GoProStitcherKitTests/AudioExtractorTests.swift` - 6 tests covering all paths
- `GoProStitcherKit/Tests/GoProStitcherKitTests/Resources/GH010001_audio.MP4` - 1s MP4 fixture with audio stream

## Decisions Made
- Output placed next to source file (same directory) — matches plan spec and natural UX expectation
- Separate audio fixture `GH010001_audio.MP4` added because existing `GH010001.MP4` is video-only; ffmpeg exits 234 when attempting audio extraction (`-vn`) with no audio stream present

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added GH010001_audio.MP4 fixture with audio stream**
- **Found during:** Task 2 (AudioExtractorTests)
- **Issue:** Existing GH010001.MP4 has no audio stream; ffmpeg exits 234 on `-vn` extraction, causing 4 test failures
- **Fix:** Generated 1-second h264+aac MP4 fixture via ffmpeg lavfi sources; updated tests to use it for ffmpeg-dependent tests while original fixture still used by other test suites
- **Files modified:** Resources/GH010001_audio.MP4 (created), AudioExtractorTests.swift (copyFixture uses new name)
- **Verification:** All 6 AudioExtractorTests pass; full suite 59 tests 0 failures
- **Committed in:** `8ffd313` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Required fixture addition to enable actual ffmpeg extraction tests. No scope creep — plan assumed a usable video+audio fixture existed.

## Issues Encountered
- GH010001.MP4 fixture lacks audio stream — ffmpeg returns exit 234 for `-vn` extraction against video-only file. Resolved by generating a proper audio-bearing fixture.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- AudioExtractor engine complete and fully tested
- Ready for Phase 6: AudioExtractor UI wiring (TCA feature, file picker, progress state)
- No blockers

---
*Phase: 05-audioextractor-engine*
*Completed: 2026-03-18*
