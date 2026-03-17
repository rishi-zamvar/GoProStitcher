---
phase: 02-file-detection
plan: 01
subsystem: parsing
tags: [swift, gopro, regex, nsr-regular-expression, value-types, tdd]

# Dependency graph
requires:
  - phase: 01-testing-infrastructure
    provides: GoProStitcherKit SPM package, TempDirectoryHelper, GoProFileFactory, test infrastructure
provides:
  - GoProChunk value type (Equatable, Hashable, computed filename)
  - GoProNameParser.parse() — regex-based GoPro filename parser returning GoProChunk?
  - GoProNameParser.sortedChunks() — canonical stitch order (fileNumber asc, chapter asc)
  - 17 TDD tests covering parse/reject/sort/equatable/filename behaviors
affects: [03-file-scanner, 04-stitch-engine, any phase reading GoPro filenames from disk]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "NSRegularExpression for regex in swift-tools-version 5.9 (Swift regex literals not available)"
    - "GoProNameParser as caseless enum — namespace for static functions, no instantiation"
    - "TDD RED-GREEN: test file committed failing, then implementation committed passing"

key-files:
  created:
    - GoProStitcherKit/Sources/GoProStitcherKit/GoProNameParser.swift
    - GoProStitcherKit/Tests/GoProStitcherKitTests/GoProNameParserTests.swift
  modified: []

key-decisions:
  - "NSRegularExpression instead of Swift regex literal (/.../) — literals require swift-tools-version 5.7+ with Xcode 14+, but the package toolchain rejected them; NSRegularExpression is universally safe"
  - "sortedChunks() key: fileNumber asc then chapter asc — fileNumber is the recording session, chapter is the split within that session; this order is the correct stitch sequence"
  - "GoProNameParser as enum (not struct/class) — prevents instantiation; pure static interface is the right model for a namespace of pure functions"

patterns-established:
  - "GoProChunk.filename: computed var reconstructs original name — single source of truth for format string"
  - "parse() returns Optional<GoProChunk> — nil for any non-matching filename, no throws needed"

# Metrics
duration: 2min
completed: 2026-03-17
---

# Phase 2 Plan 1: GoProNameParser Summary

**Pure GoPro filename parser using NSRegularExpression, producing typed GoProChunk values with sort-order support, verified by 17 TDD tests covering parse/reject/sort/equatable/filename**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-17T18:32:55Z
- **Completed:** 2026-03-17T18:35:04Z
- **Tasks:** 2 (RED + GREEN)
- **Files modified:** 2

## Accomplishments
- GoProChunk value type: Equatable, Hashable, with computed `filename` property that reconstructs the original GoPro filename
- GoProNameParser.parse() using NSRegularExpression with pattern `^(GH|GX)(\d{2})(\d{4})\.MP4$` — rejects lowercase, wrong prefixes, wrong extensions, truncated names
- GoProNameParser.sortedChunks() sorts by fileNumber ascending then chapter ascending (canonical stitch order)
- 17 tests: 5 valid-parse cases, 6 rejection cases, 3 sort cases, 1 equatable, 2 filename cases — all pass

## Task Commits

Each task was committed atomically:

1. **Task 1: RED — failing GoProNameParserTests** - `7c35cbc` (test)
2. **Task 2: GREEN — GoProNameParser implementation** - `24b20ec` (feat)

_TDD plan: 2 commits (test → feat). No refactor pass needed._

## Files Created/Modified
- `GoProStitcherKit/Sources/GoProStitcherKit/GoProNameParser.swift` - GoProChunk struct + GoProNameParser enum with parse/sortedChunks
- `GoProStitcherKit/Tests/GoProStitcherKitTests/GoProNameParserTests.swift` - 17 TDD tests

## Decisions Made
- Used NSRegularExpression (not Swift regex literal `/pattern/`) because swift-tools-version 5.9 with the installed toolchain does not support regex literals as stored properties — they produced parse errors. NSRegularExpression is universally compatible.
- GoProNameParser as a caseless `enum` rather than `struct` or `class` — prevents accidental instantiation; the type is a pure function namespace.
- Sort key: fileNumber first (session), chapter second (split within session). This matches the physical GoPro recording split order.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced Swift regex literal with NSRegularExpression**
- **Found during:** Task 2 (GREEN implementation)
- **Issue:** Plan specified `parse() uses regex ^(GH|GX)(\d{2})(\d{4})\.MP4$` — implemented as Swift regex literal `/pattern/`, which produced 20+ compile errors under swift-tools-version 5.9 on this toolchain
- **Fix:** Rewrote using `NSRegularExpression` with a raw string pattern. Semantics are identical; only the Swift API surface changed.
- **Files modified:** GoProStitcherKit/Sources/GoProStitcherKit/GoProNameParser.swift
- **Verification:** `swift test --package-path GoProStitcherKit --filter GoProNameParserTests` — 17/17 pass
- **Committed in:** 24b20ec (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary for compilation. Behavior is identical to what the plan specified — same pattern, same semantics, no scope creep.

## Issues Encountered
- Swift regex literal syntax (`/^(GH|GX)(\d{2})(\d{4})\.MP4$/`) is not supported as a stored property type under the installed toolchain despite swift-tools-version 5.9. NSRegularExpression is the reliable fallback for macOS 13-compatible SPM packages.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- GoProChunk and GoProNameParser are exported from GoProStitcherKit and ready for use in Phase 3 file-scanner work
- The parser is pure (no I/O) — Phase 3 can wrap it with FileManager directory enumeration
- No blockers

---
*Phase: 02-file-detection*
*Completed: 2026-03-17*
