# ROADMAP: GoProStitcher

**Project Value:** A DJ/creator can go from a folder of split GoPro chunks to a single continuous video file with minimal disk usage, no file duplication, and confidence that originals are safely archived.

**Depth:** Quick (3-5 phases, 1-3 plans each)
**Total Requirements:** 15 v1
**Phases:** 4

---

## Phase 1: Testing Infrastructure & Project Foundation

**Goal:** Xcode project is scaffolded with test targets, test utilities, and mock MP4 generators ready to support feature development.

**Dependencies:** None (foundational)

**Requirements Mapped:**
- TEST-01: Unit test framework configured with test targets for logic, file I/O, and UI
- TEST-02: Mock MP4 generator utility creates small test fixtures with valid MP4 headers and GoPro naming patterns
- TEST-03: Test helpers for file system operations (temp directories, cleanup, validation)
- TEST-04: CI-ready test runner (xcodebuild commands, test output parsing, failure reporting)

**Success Criteria:**

1. Xcode project created with app target and separate test targets (unit, integration, UI)
2. Mock MP4 generator creates valid MP4 files with customizable duration, resolution, and GoPro naming
3. Test helpers provide temp directory management, file cleanup, and standard assertions
4. Full test suite runs with `xcodebuild test` and produces pass/fail summary
5. Test infrastructure is documented and ready for feature phase integration

---

## Phase 2: File Detection (with Tests)

**Goal:** User can select a folder and app reliably detects GoPro chunks with correct stitch order, verified by comprehensive tests.

**Dependencies:** Requires Phase 1 (testing infrastructure)

**Requirements Mapped:**
- DETECT-01: User can select a folder via native macOS file picker dialog
- DETECT-02: App validates folder contains .mp4 files; shows clear error if empty or no MP4s found
- DETECT-03: App parses GoPro naming convention (GH/GX prefix, chapter/file number pattern) to determine correct stitch order
- DETECT-04: App displays total file count and combined size before proceeding

**Success Criteria:**

1. User can click "Select Folder" button and native macOS file picker opens
2. Unit tests verify GoPro naming parser handles GH/GX prefix variations and orders files by chapter number correctly
3. Integration tests confirm app validates empty folder, rejects non-MP4 files, and displays appropriate error messages
4. App correctly displays total file count, combined size, and resolution for selected folder
5. All DETECT-01 through DETECT-04 requirements pass automated tests with mock MP4 fixtures from Phase 1

---

## Phase 3: Review, Preview & Reorder (with Tests)

**Goal:** User can verify detected files with quick preview and reorder them if needed, with full test coverage for preview and drag interactions.

**Dependencies:** Requires Phase 2 (file detection)

**Requirements Mapped:**
- ORDER-01: App shows detected files in stitch order with video thumbnails
- ORDER-02: User can play first few seconds of any clip for quick verification
- ORDER-03: User can drag to reorder files if auto-detected order is wrong
- ORDER-04: Each file shows duration, file size, and resolution metadata

**Success Criteria:**

1. User sees list of detected files with thumbnails extracted from first frame of each mock MP4
2. User can click any file and quick-preview plays first 3 seconds of video
3. Unit tests verify drag-to-reorder reorders files correctly in memory; UI tests confirm visual reordering works
4. Each file displays duration, size (MB), and resolution (e.g., "1920x1080, 4.2 MB, 45s")
5. Preview modal closes cleanly; all ORDER-01 through ORDER-04 requirements pass automated tests

---

## Phase 4: Stitching & Archive with Full Integration Testing

**Goal:** App stitches verified files in-place with clear progress, archives originals, and entire pipeline is validated through end-to-end tests.

**Dependencies:** Requires Phase 3 (review/reorder)

**Requirements Mapped:**
- STITCH-01: App stitches files by sequentially appending each chunk to file 1 in-place — no intermediate copies or file duplication
- STITCH-02: Progress bar with text showing current phase and which file is being processed (e.g., "Stitching 3/7: GH030001.MP4")
- STITCH-03: After stitching completes, each original chunk is individually zipped into an `archive/` subfolder at the source location

**Success Criteria:**

1. User sees "Start Stitching" button and can initiate the process; progress screen appears
2. Full integration test runs detect → preview → order → stitch → archive on 3-4 mock MP4 chunks; file output is validated
3. Unit tests verify append logic produces correct binary concatenation; disk space monitoring confirms no duplicate files created
4. Archive creation starts after stitching completes; user sees "Archiving: chunk 1/7" updates; all chunks are individually zipped
5. Complete end-to-end test suite passes (95%+ coverage); all STITCH-01 through STITCH-03 requirements verified, plus error scenarios (insufficient disk, interrupted operations, corrupted MP4s)

---

## Progress & Execution

| Phase | Status | Start | End | Notes |
|-------|--------|-------|-----|-------|
| 1 - Testing Infrastructure & Project Foundation | ✓ Complete | 2026-03-17 | 2026-03-17 | 2 plans, 9/9 must-haves verified |
| 2 - File Detection (with Tests) | Pending | — | — | File picker, validation, GoPro parsing with unit/integration tests |
| 3 - Review, Preview & Reorder (with Tests) | Pending | — | — | Thumbnails, quick preview, drag-to-reorder with UI tests |
| 4 - Stitching & Archive with Full Integration Testing | Pending | — | — | In-place append, progress tracking, zip creation, end-to-end tests |

---

## Coverage Validation

**Requirement Mapping:**

| Requirement | Phase | Category | Status |
|-------------|-------|----------|--------|
| TEST-01 | 1 | Testing Infrastructure | Complete |
| TEST-02 | 1 | Testing Infrastructure | Complete |
| TEST-03 | 1 | Testing Infrastructure | Complete |
| TEST-04 | 1 | Testing Infrastructure | Complete |
| DETECT-01 | 2 | File Detection | Pending |
| DETECT-02 | 2 | File Detection | Pending |
| DETECT-03 | 2 | File Detection | Pending |
| DETECT-04 | 2 | File Detection | Pending |
| ORDER-01 | 3 | Review & Order | Pending |
| ORDER-02 | 3 | Review & Order | Pending |
| ORDER-03 | 3 | Review & Order | Pending |
| ORDER-04 | 3 | Review & Order | Pending |
| STITCH-01 | 4 | Stitching | Pending |
| STITCH-02 | 4 | Stitching | Pending |
| STITCH-03 | 4 | Stitching | Pending |

**Coverage Summary:**
- Total v1 requirements: 15
- Mapped to phases: 15
- Unmapped: 0
- Coverage: 100% ✓

---

*Roadmap created: 2026-03-17*
*Roadmap revised (test-first): 2026-03-17*
*Depth: quick (3-5 phases)*
*Next: `/gsd:plan-phase 1`*
