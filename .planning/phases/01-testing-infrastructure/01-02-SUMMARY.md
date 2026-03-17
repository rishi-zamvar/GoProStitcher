---
phase: 01-testing-infrastructure
plan: 02
subsystem: testing
tags: [swift, xctest, goprostitcherkit, tempdir, factory, xcodebuild, ci]

# Dependency graph
requires:
  - phase: 01-testing-infrastructure plan 01
    provides: GoProStitcherKit SPM package and 3 test targets all compiling
provides:
  - TempDirectoryHelper public API (create/cleanup) usable from any test target
  - GoProFileFactory public API (makeChunk/makeSequence/goProName) for synthetic GoPro file creation
  - 6 passing TestHelpersTests validating helper behavior
  - scripts/run-tests.sh CI script that runs SPM + Xcode test suite
  - .gitignore covering DerivedData, test-data/, .build/, xcuserstate
  - GoProStitcherIntegrationTests/Resources/README.md documenting fixture strategy
affects:
  - 02-file-ingestion
  - 03-preview-reorder
  - 04-stitching-engine

# Tech tracking
tech-stack:
  added: []
  patterns:
    - TempDirectoryHelper + tearDown.cleanup(url:) pattern for isolated test filesystem
    - GoProFileFactory.makeSequence for ordered GoPro chunk sets in tests
    - goProName() pure formatter for name-parsing unit tests (no I/O)

key-files:
  created:
    - GoProStitcherKit/Sources/GoProStitcherKit/TestHelpers/TempDirectoryHelper.swift
    - GoProStitcherKit/Sources/GoProStitcherKit/TestHelpers/GoProFileFactory.swift
    - GoProStitcherKit/Tests/GoProStitcherKitTests/TestHelpersTests.swift
    - scripts/run-tests.sh
    - .gitignore
    - GoProStitcherIntegrationTests/Resources/README.md
  modified: []

key-decisions:
  - "setUp() does not throw on macOS XCTest — use try? + XCTAssertNotNil pattern"
  - "test-data/ gitignored for large real GoPro clips; tiny fixtures committed to Resources/"
  - "xcpretty treated as optional in run-tests.sh with || true to avoid CI failure when not installed"

patterns-established:
  - "TempDirectory pattern: call TempDirectoryHelper.create() in setUp, cleanup(url:) in tearDown"
  - "GoPro filename format: prefix(2) + chapter(2-digit zero-padded) + fileNumber(4-digit zero-padded) + .MP4"
  - "GoProFileFactory.makeSequence for ordered chunk sets, makeChunk for single targeted files"

# Metrics
duration: 3min
completed: 2026-03-17
---

# Phase 1 Plan 02: Test Helpers + CI Script Summary

**Reusable TempDirectoryHelper and GoProFileFactory test utilities with 6 passing tests, CI-ready run-tests.sh, and gitignore covering large fixture files**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-17T17:42:41Z
- **Completed:** 2026-03-17T17:45:37Z
- **Tasks:** 2
- **Files modified:** 6 created

## Accomplishments

- `TempDirectoryHelper` provides create/cleanup for isolated per-test filesystem directories
- `GoProFileFactory` generates synthetic GoPro-named MP4 files (GH/GX prefix + 2-digit chapter + 4-digit fileNumber) at arbitrary byte sizes
- 6 TestHelpersTests all pass via `swift test --package-path GoProStitcherKit`
- `scripts/run-tests.sh` runs SPM tests + xcodebuild test suite, exits 0 on all-pass
- `.gitignore` covers DerivedData/, test-data/, .build/, *.xcuserstate
- `GoProStitcherIntegrationTests/Resources/README.md` documents tiny-fixture commit strategy vs large-file gitignore strategy

## Task Commits

Each task was committed atomically:

1. **Task 1: TempDirectoryHelper + GoProFileFactory with tests** - `7a79c37` (feat)
2. **Task 2: CI test runner script + .gitignore + test-data directory** - `29ec517` (feat)

**Plan metadata:** (created next — see docs commit)

## Public API Reference

### TempDirectoryHelper

```swift
public struct TempDirectoryHelper {
    public static func create() throws -> URL
    public static func cleanup(url: URL)
}
```

Usage in tests:
```swift
private var tempDir: URL!

override func setUp() {
    super.setUp()
    tempDir = try? TempDirectoryHelper.create()
    XCTAssertNotNil(tempDir)
}

override func tearDown() {
    TempDirectoryHelper.cleanup(url: tempDir)
    tempDir = nil
    super.tearDown()
}
```

### GoProFileFactory

```swift
public struct GoProFileFactory {
    // Create a single GoPro-named chunk file
    public static func makeChunk(
        in directory: URL,
        chapter: Int,        // 1-99 → 2-digit zero-padded
        fileNumber: Int,     // 1-9999 → 4-digit zero-padded
        prefix: String = "GH",   // "GH" or "GX"
        sizeBytes: Int = 1024
    ) throws -> URL

    // Create count chunks with chapters 1..count
    public static func makeSequence(
        in directory: URL,
        count: Int,
        prefix: String = "GH",
        fileNumber: Int = 1,
        chunkSizeBytes: Int = 1024
    ) throws -> [URL]

    // Pure name formatter — no file system I/O
    public static func goProName(prefix: String, chapter: Int, fileNumber: Int) -> String
}
```

### GoPro Filename Format

`GH010001.MP4` = prefix(GH) + chapter(01) + fileNumber(0001) + .MP4

- prefix: "GH" (H.265/HEVC) or "GX" (H.264/AVC)
- chapter: 2-digit zero-padded (01-99)
- fileNumber: 4-digit zero-padded (0001-9999)

## CI Script

Location: `scripts/run-tests.sh`

```bash
bash scripts/run-tests.sh   # runs all tests, exits 0 on pass
```

The script:
1. Runs `swift test --package-path GoProStitcherKit` (unit tests)
2. Runs `xcodebuild test -project GoProStitcher.xcodeproj ...` (integration + UI)
3. Prints "=== ALL TESTS PASSED ===" and exits 0 if both pass
4. xcpretty is optional — script uses `|| true` to avoid failure if not installed

## Test Fixture Strategy

| Location | Contents | In git? |
|---|---|---|
| `GoProStitcherIntegrationTests/Resources/` | Tiny GoPro clips (1-5 MB) for CI-safe integration tests | Yes |
| `test-data/` | Full-size 4 GB GoPro chunks for local testing | No — gitignored |

See `GoProStitcherIntegrationTests/Resources/README.md` for required filenames (GH010001.MP4, GH020001.MP4, GH030001.MP4).

## Files Created/Modified

- `GoProStitcherKit/Sources/GoProStitcherKit/TestHelpers/TempDirectoryHelper.swift` — public temp dir utility
- `GoProStitcherKit/Sources/GoProStitcherKit/TestHelpers/GoProFileFactory.swift` — synthetic GoPro file factory + GoProFileFactoryError enum
- `GoProStitcherKit/Tests/GoProStitcherKitTests/TestHelpersTests.swift` — 6 tests covering all helper behavior
- `scripts/run-tests.sh` — CI-ready test runner (executable)
- `.gitignore` — covers Xcode build artifacts and large test fixtures
- `GoProStitcherIntegrationTests/Resources/README.md` — fixture documentation

## Decisions Made

- `setUp()` does not support `throws` on macOS XCTest — used `try?` + `XCTAssertNotNil` pattern instead
- `test-data/` gitignored for large real GoPro clips; tiny committed fixtures go in `Resources/`
- `xcpretty` treated as optional with `|| true` — raw xcodebuild output captured regardless

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed setUp() throws not supported on macOS XCTest**

- **Found during:** Task 1 (TestHelpersTests.swift compilation)
- **Issue:** Plan template used `override func setUp() throws` which fails to compile on macOS XCTest — `XCTest.setUp()` is non-throwing so override cannot add `throws`
- **Fix:** Changed to `override func setUp()` with `try?` + `XCTAssertNotNil` pattern
- **Files modified:** GoProStitcherKit/Tests/GoProStitcherKitTests/TestHelpersTests.swift
- **Verification:** All 6 tests compile and pass
- **Committed in:** `7a79c37` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Required for compilation. No scope creep.

## Issues Encountered

None beyond the setUp() throws issue documented above.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Feature phases (2-4) can now:
- Use `TempDirectoryHelper` for isolated test filesystem directories
- Use `GoProFileFactory.makeChunk/makeSequence` for synthetic GoPro file sets
- Run `bash scripts/run-tests.sh` for full CI validation
- Add real tiny MP4 fixtures to `GoProStitcherIntegrationTests/Resources/` when integration tests are written

No blockers. Phase 2 file ingestion work can begin immediately.

---
*Phase: 01-testing-infrastructure*
*Completed: 2026-03-17*
