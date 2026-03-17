# STATE: GoProStitcher

**Last Updated:** 2026-03-17 (Plan 02-03 complete)

---

## Project Reference

**Core Value:** A DJ/creator can go from a folder of split GoPro chunks to a single continuous video file with minimal disk usage, no file duplication, and confidence that originals are safely archived.

**Key Constraints:**
- macOS desktop app only (Swift/SwiftUI)
- Sequential binary append (no intermediate file duplication)
- In-place stitching to first file
- Individual zip per chunk into archive/ subfolder
- Three-screen UI: folder picker → review/reorder/preview → progress
- Test-first approach: comprehensive testing infrastructure built before feature implementation

**Milestone:** v1.0 (complete app for basic folder stitching)

---

## Current Position

**Phase:** 2 - File Detection (Complete)
**Plan:** 02-03 complete — FolderPickerFeature TCA reducer + FolderPickerView implemented and user-verified
**Status:** Plan 02-03 complete. Phase 2 all 3 plans done. DETECT-01 through DETECT-04 user-verified.

**Progress:** ███████░░░ 70% (Phase 1 complete + Phase 2 complete — all 3 plans)

**Current Focus:**
Phase 2 complete. GoProNameParser, FolderScanner, and FolderPickerFeature/View all done. Ready for Phase 3 (review screen with reorder/preview).

---

## Performance Metrics

**Execution Mode:** yolo (rapid iteration)
**Depth:** quick (3-5 phases, 1-3 plans each)
**Parallelization:** Enabled
**Plan Check:** Disabled
**Verifier:** Enabled
**Commit Docs:** Enabled

**KPIs (v1 success):**
- Phase 1 completion: Xcode project, test targets, mock MP4 generator, test helpers all working
- Phase 2 completion: File picker, validation, GoPro parsing working with comprehensive unit/integration tests
- Phase 3 completion: Preview and drag-to-reorder functional with UI tests passing
- Phase 4 completion: Stitching produces correct output, archives created, no duplicate files on disk, 95%+ test coverage, all error scenarios handled

---

## Accumulated Context

### Decisions Made

| Decision | Rationale | Status |
|----------|-----------|--------|
| Test-first approach | Comprehensive testing infrastructure built first ensures all features tested uniformly and integrated properly | Locked for all phases |
| Sequential append to file 1 | Avoids duplicating 12GB+ files | Locked for Phase 4 |
| Individual zip per chunk | Easier to find/extract specific chunks if needed | Locked for Phase 4 |
| Three-screen UI | Minimal surface for utility tool | Locked across all phases |
| GoPro naming parsing with fuzzy match | Handle variations in GoPro chapter numbering | Locked for Phase 2 |
| xcodegen + project.yml as Xcode project source-of-truth | Regenerable, diff-friendly; avoids manual pbxproj editing | From 01-01 |
| GoProStitcherKitTests runs via swift test not xcodebuild | Lives inside SPM package; not an Xcode target | From 01-01 |
| swift-tools-version 5.9 (not 6.2) | Matches plan requirement and macOS 13 deployment target | From 01-01 |
| setUp() does not throw on macOS XCTest | Use try? + XCTAssertNotNil pattern; override cannot add throws | From 01-02 |
| test-data/ gitignored, tiny fixtures in Resources/ | Large real GoPro clips excluded from git; CI-safe tiny clips committed | From 01-02 |
| xcpretty optional in run-tests.sh | Uses || true to avoid CI failure when xcpretty not installed | From 01-02 |
| NSRegularExpression instead of Swift regex literal | Swift regex literals (/.../) fail as stored properties under swift-tools-version 5.9 on the installed toolchain; NSRegularExpression is universally safe | From 02-01 |
| GoProNameParser as caseless enum | Prevents instantiation; pure static function namespace is the right model | From 02-01 |
| Sort key: fileNumber asc then chapter asc | fileNumber = recording session, chapter = split within session; this order is the correct stitch sequence | From 02-01 |
| FolderScanResult.empty covers both empty dirs and non-MP4-only dirs | Neither case has scannable content; callers don't need the distinction | From 02-02 |
| ScannedChunk is a value type (struct) with chunk + url + sizeBytes | Immutable, Equatable, aggregates parsed metadata and filesystem facts in one type | From 02-02 |
| userCancelledPicker is a distinct TCA action (not scanCompleted(.empty)) | Cancel must not overwrite a prior valid scan result; dedicated action only resets isLoading | From 02-03 |
| NSOpenPanel via MainActor.run inside TCA .run effect | AppKit requires runModal() on main thread; this satisfies both AppKit and TCA concurrency rules | From 02-03 |
| TCA Feature pattern: Features/FeatureName/FeatureNameFeature.swift + FeatureNameView.swift | One file per reducer, one file per view, under Features/ directory hierarchy | From 02-03 |

### Known Constraints

- **Performance:** Files are 12GB+; must avoid memory buffering entire file
- **File Validation:** GoPro MP4s may be corrupted mid-recording (user interrupted); error handling required
- **Disk Space:** User may not have 2x space needed for duplication; binary append is critical
- **Platform:** macOS 12+ (recent SwiftUI features assumed)
- **Testing:** Mock MP4 fixtures must have valid headers; temp directory cleanup must be reliable

### TODO (Backlog)

- [x] Design test helper APIs for file system operations — DONE in 01-02
- [ ] Add real tiny MP4 fixtures to GoProStitcherIntegrationTests/Resources/ (GH010001.MP4, GH020001.MP4, GH030001.MP4) before Phase 2 integration tests
- [ ] Research AVFoundation quick preview performance (3-second clip extraction timing)
- [x] Identify GoPro chapter numbering variations (GH010001 vs GX010001 vs other patterns) — DONE in 02-01
- [ ] Confirm FileManager disk space API for checking available space before append

### Blockers

None identified at this stage.

---

## Session Continuity

**Last Session:** 2026-03-17 - Executed plan 02-03 (FolderPickerFeature)
**Stopped at:** Completed 02-03-PLAN.md (1 auto task + checkpoint human-verify, all verified)
**Resume file:** None

**Artifacts Updated:**
- GoProStitcher/Features/FolderPicker/FolderPickerFeature.swift
- GoProStitcher/Features/FolderPicker/FolderPickerView.swift
- GoProStitcher/ContentView.swift
- GoProStitcher.xcodeproj/project.pbxproj
- .planning/phases/02-file-detection/02-03-SUMMARY.md

**Next Session:** Execute Phase 3 (review screen — chunk reorder, preview, proceed to stitch)

---

*State initialized: 2026-03-17 by roadmapper*
*State revised: 2026-03-17 for test-first approach*
