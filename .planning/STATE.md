# STATE: GoProStitcher

**Last Updated:** 2026-03-17 (Plan 02-01 complete)

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

**Phase:** 2 - File Detection (In Progress)
**Plan:** 02-01 complete — GoProNameParser + GoProChunk implemented and tested
**Status:** Plan 02-01 complete. 2 tasks / 2 done. 25/25 tests passing.

**Progress:** ████░░░░░░ 37% (Phase 1 complete + Plan 02-01 complete)

**Current Focus:**
Phase 2 underway. GoProNameParser (pure parsing) done. Next: 02-02 file scanner / directory enumeration.

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

**Last Session:** 2026-03-17 18:35 UTC - Executed plan 02-01
**Stopped at:** Completed 02-01-PLAN.md (2/2 tasks)
**Resume file:** None

**Artifacts Updated:**
- GoProStitcherKit/Sources/GoProStitcherKit/GoProNameParser.swift
- GoProStitcherKit/Tests/GoProStitcherKitTests/GoProNameParserTests.swift
- .planning/phases/02-file-detection/02-01-SUMMARY.md

**Next Session:** Execute Phase 2 Plan 02 (file scanner / directory enumeration wrapping GoProNameParser)

---

*State initialized: 2026-03-17 by roadmapper*
*State revised: 2026-03-17 for test-first approach*
