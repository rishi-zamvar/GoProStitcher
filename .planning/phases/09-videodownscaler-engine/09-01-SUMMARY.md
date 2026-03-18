---
phase: 09-videodownscaler-engine
plan: 01
subsystem: video-processing
tags: [ffmpeg, ffprobe, swift, spm, h264, libx264, progress-pipe, lavfi]

# Dependency graph
requires:
  - phase: 05-audioextractor-engine
    provides: AudioExtractor caseless enum pattern, probeDuration helper, TempDirectoryHelper, collision-free naming
provides:
  - VideoDownscalerError enum (5 cases, LocalizedError + Equatable)
  - DownscaleProgress struct (fraction, secondsProcessed, totalSeconds, bitrateKbps, fps)
  - VideoDownscaler.downscale(url:outputName:progress:) static method
  - 8 passing unit tests covering all error paths, collision, progress, and encoding
affects:
  - 10-downscale-ui (wires VideoDownscaler into TCA feature)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Caseless Swift enum as namespace for static processing method (mirrors AudioExtractor)"
    - "ffprobe resolution guard before encoding to block already-1080p inputs"
    - "ffmpeg -progress pipe:1 parsed for rich DownscaleProgress (out_time_us, bitrate, fps)"
    - "Defer-block partial output cleanup on any throw after outputURL is determined"
    - "lavfi synthetic fixture generation in tests (no bundled binary fixture needed)"

key-files:
  created:
    - GoProStitcherKit/Sources/GoProStitcherKit/VideoDownscalerError.swift
    - GoProStitcherKit/Sources/GoProStitcherKit/DownscaleProgress.swift
    - GoProStitcherKit/Sources/GoProStitcherKit/VideoDownscaler.swift
    - GoProStitcherKit/Tests/GoProStitcherKitTests/VideoDownscalerTests.swift
  modified: []

key-decisions:
  - "DownscaleProgress placed in its own file so UI layer can import just the type"
  - "outputName param takes full filename (stem.ext) not stem-only, unlike AudioExtractor which derives stem from input URL"
  - "collisionFreeURL accepts full name and splits on last dot — handles dots in stem gracefully"
  - "probeResolution returns nil on ffprobe failure — guard is advisory, not blocking, to avoid false rejections"
  - "lavfi fixtures generated at test runtime (blue 4K + red 1080p, 2s ultrafast) — no bundled binary needed"

patterns-established:
  - "DownscaleProgress: rich struct vs AudioExtractor tuple callback — use struct pattern for new tools"
  - "Resolution guard pattern: ffprobe → height check → throw .alreadyAtTargetResolution before any encode"

# Metrics
duration: 4min
completed: 2026-03-18
---

# Phase 9 Plan 01: VideoDownscaler Engine Summary

**VideoDownscaler engine shipping H.264 1080p re-encoding via ffmpeg with resolution guard, progress parsing, collision-free naming, and 8 passing unit tests**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-18T15:08:14Z
- **Completed:** 2026-03-18T15:12:00Z
- **Tasks:** 2
- **Files modified:** 4 (all created)

## Accomplishments

- Three source files implementing the complete VideoDownscaler engine (error type, progress struct, engine)
- Resolution guard via ffprobe blocks already-1080p or lower inputs before any encoding begins
- Progress callback parses out_time_us, bitrate, fps from ffmpeg -progress pipe:1 into typed DownscaleProgress struct
- 8-test suite using lavfi-generated synthetic fixtures (no bundled binaries needed); 7 pass, 1 skip (ffmpegNotFound skips when ffmpeg is present as expected)
- Full GoProStitcherKit suite: 67 tests, 2 skipped, 0 failures — no regressions

## Task Commits

Each task was committed atomically:

1. **Task 1: VideoDownscalerError, DownscaleProgress, VideoDownscaler** - `da89168` (feat)
2. **Task 2: VideoDownscalerTests** - `c9882c3` (test)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `GoProStitcherKit/Sources/GoProStitcherKit/VideoDownscalerError.swift` - 5-case typed error enum (ffmpegNotFound, inputNotFound, alreadyAtTargetResolution, encodingFailed, outputWriteFailed)
- `GoProStitcherKit/Sources/GoProStitcherKit/DownscaleProgress.swift` - Public struct with fraction, secondsProcessed, totalSeconds, bitrateKbps, fps
- `GoProStitcherKit/Sources/GoProStitcherKit/VideoDownscaler.swift` - Caseless enum with downscale(url:outputName:progress:) + private probeResolution/probeDuration/collisionFreeURL helpers
- `GoProStitcherKit/Tests/GoProStitcherKitTests/VideoDownscalerTests.swift` - 8 unit tests with lavfi fixture generation

## Decisions Made

- `DownscaleProgress` placed in its own file (not nested in VideoDownscaler.swift) so Phase 10 UI can import just the type independently
- `outputName` takes full filename `stem.ext` rather than deriving stem from input URL — gives caller explicit control over output naming
- `collisionFreeURL` splits on the last `.` so stems containing dots are handled correctly
- `probeResolution` returns nil on any ffprobe failure (ffprobe absent, parse error) — guard is advisory, not blocking, avoiding false rejections on unusual inputs
- Lavfi synthetic fixture generation at test runtime (blue 4K, red 1080p, 2s, ultrafast/crf35) — avoids needing bundled binary test files

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed `String.lastPathComponent` compilation error**

- **Found during:** Task 1 (VideoDownscaler.swift)
- **Issue:** Plan specified `outputName.lastPathComponent` but `String` does not have `lastPathComponent` — that is a `URL` member
- **Fix:** Changed to `URL(fileURLWithPath: outputName).lastPathComponent`
- **Files modified:** GoProStitcherKit/Sources/GoProStitcherKit/VideoDownscaler.swift
- **Verification:** Build exits 0 after fix
- **Committed in:** `da89168` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Single API misquote in plan spec; trivial fix, no scope change.

## Issues Encountered

None beyond the single compilation error noted above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- VideoDownscaler engine fully tested and ready for Phase 10 UI wiring
- Phase 10 should call `VideoDownscaler.downscale(url:outputName:progress:)` and bind the `DownscaleProgress` struct to a `RetroProgressBar` via TCA state
- No blockers

---
*Phase: 09-videodownscaler-engine*
*Completed: 2026-03-18*
