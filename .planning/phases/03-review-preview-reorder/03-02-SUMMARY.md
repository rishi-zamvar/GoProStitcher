---
phase: 03-review-preview-reorder
plan: 02
subsystem: ui
tags: [tca, composable-architecture, reducer, swift, xcodegen, unit-tests, chunk-review]

# Dependency graph
requires:
  - phase: 03-01
    provides: AVMetadataReader async API used in loadMetadata effect
  - phase: 02-02
    provides: ScannedChunk type stored in ChunkReviewFeature.State.chunks
  - phase: 02-03
    provides: TCA @Reducer pattern established by FolderPickerFeature
provides:
  - ChunkReviewFeature TCA @Reducer with reorder, preview-selection, and async metadata loading
  - ChunkMetadata struct (duration, resolution, thumbnail) with NSImage-safe Equatable
  - 4 passing unit tests covering reorder (Array.move semantics) and preview state transitions
affects: 03-03

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "TCA TestStore mutation pattern: closure mutates expected state rather than using XCTAssertEqual"
    - "TEST_HOST/BUNDLE_LOADER in project.yml for integration tests that need @testable app access"
    - "ChunkMetadata custom == excludes NSImage thumbnail (NSImage not Equatable)"

key-files:
  created:
    - GoProStitcher/Features/ChunkReview/ChunkReviewFeature.swift
    - GoProStitcherIntegrationTests/ChunkReviewReducerTests.swift
  modified:
    - project.yml
    - GoProStitcher.xcodeproj/project.pbxproj

key-decisions:
  - "TCA TestStore assertion pattern uses state mutation (state.chunks = [...]) not XCTAssertEqual inside closure"
  - "GoProStitcherIntegrationTests needs TEST_HOST/BUNDLE_LOADER to access @testable app internals"
  - "Integration test target depends on GoProStitcher app target (not standalone) to import ChunkReviewFeature"
  - "ChunkMetadata.== compares duration + resolution only; thumbnail (NSImage?) excluded — NSImage not Equatable"
  - "loadAllMetadata uses .merge(state.chunks.map { .send(.loadMetadata($0.url)) }) pattern"

patterns-established:
  - "Feature reducers live in GoProStitcher/Features/{Name}/{Name}Feature.swift"
  - "Integration test target uses host app (TEST_HOST) for @testable imports of internal app types"

# Metrics
duration: 25min
completed: 2026-03-18
---

# Phase 3 Plan 2: ChunkReviewFeature Reducer Summary

**TCA @Reducer for the chunk review screen with drag-reorder (Array.move), preview URL selection, and async AVMetadataReader integration — backed by 4 passing unit tests in GoProStitcherIntegrationTests**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-03-18T00:15:35Z
- **Completed:** 2026-03-18T00:22:00Z
- **Tasks:** 2 (TDD RED + GREEN)
- **Files modified:** 4

## Accomplishments
- `ChunkReviewFeature` TCA @Reducer with full state management for the review screen
- `ChunkMetadata` struct with custom Equatable that safely excludes `NSImage` thumbnail
- 4 unit tests passing: 2 reorder (Array.move semantics), 2 preview state transitions
- `GoProStitcherIntegrationTests` target wired to host app via `TEST_HOST`/`BUNDLE_LOADER`

## Task Commits

Each task was committed atomically:

1. **Task 1: RED — failing ChunkReviewReducerTests** - `2afe89e` (test)
2. **Task 2: GREEN — ChunkReviewFeature reducer** - `ec0c9e0` (feat)

_Note: TDD plan — RED commit first, then GREEN implementation commit._

## Files Created/Modified
- `GoProStitcher/Features/ChunkReview/ChunkReviewFeature.swift` - TCA @Reducer: State, Action, Reduce body, ChunkMetadata
- `GoProStitcherIntegrationTests/ChunkReviewReducerTests.swift` - 4 unit tests for reorder + preview
- `project.yml` - Added TCA dep to integration tests (later removed in favor of host app); added TEST_HOST/BUNDLE_LOADER; added `- target: GoProStitcher` dep
- `GoProStitcher.xcodeproj/project.pbxproj` - Regenerated via xcodegen

## Decisions Made
- **TCA TestStore mutation pattern**: The assertion closure receives `inout` state and must be mutated to match expected output — not used with `XCTAssertEqual` directly. Initial tests used the wrong pattern; corrected before GREEN commit.
- **GoProStitcherIntegrationTests as hosted tests**: Setting `TEST_HOST = $(BUILT_PRODUCTS_DIR)/GoProStitcher.app/Contents/MacOS/GoProStitcher` and `BUNDLE_LOADER = $(TEST_HOST)` lets the test bundle inject into the app process, making `@testable import GoProStitcher` work for internal types like `ChunkReviewFeature`.
- **ChunkMetadata.== excludes thumbnail**: `NSImage` doesn't conform to `Equatable`. Custom `==` compares `duration` and `resolution` only — sufficient for business logic (metadata equality doesn't need pixel-level image comparison).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] TCA TestStore assertion pattern was incorrect**
- **Found during:** Task 2 (GREEN — ChunkReviewFeature)
- **Issue:** Initial test file used `XCTAssertEqual(state.chunks[0], chunkC)` inside TestStore send closure. TCA's TestStore receives `inout` state and uses mutation-based expectation matching — the closure must set `state.chunks = [...]` to express the expected state, not use XCTAssert calls.
- **Fix:** Rewrote all 4 test assertions to use mutation syntax (`state.chunks = [chunkC, chunkA, chunkB]`, `state.selectedPreviewURL = targetURL`, etc.)
- **Files modified:** GoProStitcherIntegrationTests/ChunkReviewReducerTests.swift
- **Verification:** All 4 tests passed after fix
- **Committed in:** ec0c9e0 (Task 2 commit)

**2. [Rule 3 - Blocking] Integration test target needed TEST_HOST to access @testable app types**
- **Found during:** Task 2 (GREEN — after creating ChunkReviewFeature)
- **Issue:** `GoProStitcherIntegrationTests` was configured as standalone (`TEST_HOST: ""`) so `@testable import GoProStitcher` had no module to import — ChunkReviewFeature (an internal app type) was invisible.
- **Fix:** Updated `project.yml` to add `- target: GoProStitcher` dependency and set `TEST_HOST = $(BUILT_PRODUCTS_DIR)/GoProStitcher.app/Contents/MacOS/GoProStitcher` and `BUNDLE_LOADER = $(TEST_HOST)`. Regenerated xcodeproj.
- **Files modified:** project.yml, GoProStitcher.xcodeproj/project.pbxproj
- **Verification:** xcodebuild test target resolved ChunkReviewFeature successfully
- **Committed in:** ec0c9e0 (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 bug — wrong TCA assertion pattern, 1 blocking — test target configuration)
**Impact on plan:** Both fixes required for correct test execution. No scope creep.

## Issues Encountered
- Standalone integration test bundle (no TEST_HOST) cannot `@testable import` app internals — resolved by switching to hosted test bundle pattern.
- Initial `TEST_HOST` config also included explicit TCA package dep on the test target, causing duplicate-link linker errors. Resolved by removing the explicit package dep (TCA is provided via the host app).

## Next Phase Readiness
- `ChunkReviewFeature` reducer is complete and tested — ready for `ChunkReviewView` in Plan 03-03
- `GoProStitcherIntegrationTests` target now correctly configured as a hosted test bundle — future app-level integration tests can use the same pattern
- All prior test suites still green (GoProStitcherKit SPM suite: 40 tests pass)

---
*Phase: 03-review-preview-reorder*
*Completed: 2026-03-18*
