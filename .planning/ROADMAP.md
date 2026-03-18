# Roadmap: GoPro Toolkit

## Milestones

- ✅ **v1.0 Stitcher** - Phases 1-4 (shipped 2026-03-18)
- 🚧 **v1.1 Audio + Restructure** - Phases 5-7 (in progress)

## Phases

<details>
<summary>✅ v1.0 Stitcher (Phases 1-4) - SHIPPED 2026-03-18</summary>

### Phase 1: Testing Infrastructure & Project Foundation

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

### Phase 2: File Detection (with Tests)

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

### Phase 3: Review, Preview & Reorder (with Tests)

**Goal:** User can verify detected files with quick preview and reorder them if needed, with full test coverage for preview and drag interactions.

**Dependencies:** Requires Phase 2 (file detection)

**Requirements Mapped:**
- ORDER-01: App shows detected files in stitch order with video thumbnails
- ORDER-02: User can play first few seconds of any clip for quick verification
- ORDER-03: User can drag to reorder files if auto-detected order is wrong
- ORDER-04: Each file shows duration, file size, and resolution metadata

**Plans:** 3 plans

Plans:
- [x] 03-01-PLAN.md — AVMetadataReader TDD: duration, resolution, thumbnail extraction from MP4 (GoProStitcherKit)
- [x] 03-02-PLAN.md — ChunkReviewFeature TCA reducer: reorder, preview selection, metadata load with unit tests
- [x] 03-03-PLAN.md — ChunkReviewView + ChunkPreviewModal SwiftUI + ContentView navigation wiring + human-verify

**Success Criteria:**
1. User sees list of detected files with thumbnails extracted from first frame of each mock MP4
2. User can click any file and quick-preview plays first 3 seconds of video
3. Unit tests verify drag-to-reorder reorders files correctly in memory; UI tests confirm visual reordering works
4. Each file displays duration, size (MB), and resolution (e.g., "1920x1080, 4.2 MB, 45s")
5. Preview modal closes cleanly; all ORDER-01 through ORDER-04 requirements pass automated tests

---

### Phase 4: Stitching & Archive with Full Integration Testing

**Goal:** App stitches verified files in-place with clear progress, archives originals, and entire pipeline is validated through end-to-end tests.

**Dependencies:** Requires Phase 3 (review/reorder)

**Requirements Mapped:**
- STITCH-01: App stitches files by sequentially appending each chunk to file 1 in-place — no intermediate copies or file duplication
- STITCH-02: Progress bar with text showing current phase and which file is being processed (e.g., "Stitching 3/7: GH030001.MP4")
- STITCH-03: After stitching completes, each original chunk is individually zipped into an `archive/` subfolder at the source location

**Plans:** 3 plans

Plans:
- [x] 04-01-PLAN.md — ChunkStitcher + ChunkArchiver TDD: binary append and zip-per-chunk engines (GoProStitcherKit)
- [x] 04-02-PLAN.md — StitchProgressFeature TCA reducer + AppFeature navigation wiring + ChunkReview startStitching action
- [x] 04-03-PLAN.md — StitchProgressView SwiftUI + end-to-end integration test + human-verify

**Success Criteria:**
1. User sees "Start Stitching" button and can initiate the process; progress screen appears
2. Full integration test runs detect → preview → order → stitch → archive on 3-4 mock MP4 chunks; file output is validated
3. Unit tests verify append logic produces correct binary concatenation; disk space monitoring confirms no duplicate files created
4. Archive creation starts after stitching completes; user sees "Archiving: chunk 1/7" updates; all chunks are individually zipped
5. Complete end-to-end test suite passes; all STITCH-01 through STITCH-03 requirements verified, plus error scenarios

</details>

---

### 🚧 v1.1 Audio + Restructure (In Progress)

**Milestone Goal:** App renamed to GoPro Toolkit, restructured as an extensible multi-tool launcher, with a fully tested audio extraction tool that converts any MP4 to 320kbps MP3.

---

#### Phase 5: AudioExtractor Engine

**Goal:** AudioExtractor engine is built and fully tested — extraction logic, collision handling, ffmpeg availability check, and error paths all verified before any UI is wired.

**Depends on:** Phase 4

**Requirements:**
- AUDIO-02: App extracts audio as 320kbps CBR MP3 using ffmpeg libmp3lame
- AUDIO-03: MP3 saved next to source file with same name and .mp3 extension
- AUDIO-06: File collision handled — if .mp3 already exists, append suffix (e.g., `_1.mp3`)
- AUDIO-07: ffmpeg availability checked before extraction; clear error if not found
- TEST-05: AudioExtractor engine unit tested (extraction, error cases, collision handling)

**Success Criteria:**
1. `AudioExtractor.extract(url:)` runs ffmpeg with `-vn -acodec libmp3lame -b:a 320k` and produces a valid MP3 next to the source file
2. When an `.mp3` already exists at the output path, extractor appends `_1`, `_2`, etc. until the path is clear — verified by unit test
3. When ffmpeg is not found on the system, extractor returns a typed error with a human-readable message before spawning any process
4. All extraction error paths (missing input, bad codec, interrupted) return typed errors with distinct messages — verified by unit tests
5. Test suite passes with `swift test` or `xcodebuild test` — no flaky file-system side effects in CI

**Plans:** 1 plan

Plans:
- [x] 05-01-PLAN.md — AudioExtractorError + AudioExtractor engine + AudioExtractorTests (collision, error paths, extraction)

---

#### Phase 6: Audio Extraction UI

**Goal:** User can pick an MP4, watch extraction progress, and find the resulting MP3 auto-revealed in Finder — the complete audio tool flow is wired and integration-tested.

**Depends on:** Phase 5 (AudioExtractor engine)

**Requirements:**
- AUDIO-01: User can select any MP4 file via native macOS file picker
- AUDIO-04: Progress screen shows extraction status with metadata (source duration, file size, audio bitrate)
- AUDIO-05: On completion, MP3 is auto-revealed in Finder
- TEST-06: Integration test covering full extraction pipeline (pick → extract → verify MP3)

**Success Criteria:**
1. User clicks "Select File", native macOS picker opens filtered to MP4 files, and a valid selection advances to the progress screen
2. Progress screen displays source filename, duration, file size, and audio bitrate while extraction runs
3. When extraction completes, Finder opens and highlights the output MP3 — no manual navigation needed
4. Integration test exercises pick → extract → verify MP3 exists at expected path and is non-empty

**Plans:** 1 plan

Plans:
- [x] 06-01-PLAN.md — AudioFilePickerFeature + AudioExtractionFeature + AudioExtractionView + AppFeature wiring + integration test + human-verify

---

#### Phase 7: Home Screen & App Rename

**Goal:** App is named "GoPro Toolkit" throughout, presents a home screen with two tool buttons, and both tools are reachable and dismissible without breaking any existing functionality.

**Depends on:** Phase 6 (both tools complete before home wires them)

**Requirements:**
- RENAME-01: App renamed to "GoPro Toolkit" (display name, window title, bundle display name)
- HOME-01: Home screen with two big buttons: "Stitch Video" and "Extract Audio"
- HOME-02: Home screen layout is extensible — adding a third tool button requires minimal code change
- HOME-03: "Stitch Video" button launches existing stitch flow unchanged
- HOME-04: User can navigate back to home screen from any tool

**Success Criteria:**
1. App window title, dock icon tooltip, and about panel all read "GoPro Toolkit" — no "GoProStitcher" string visible to the user
2. App launches directly to a home screen showing "Stitch Video" and "Extract Audio" buttons — no other screen appears on cold launch
3. Tapping "Stitch Video" opens the existing stitch flow; every v1.0 user action works identically
4. Tapping "Extract Audio" opens the audio tool; user can complete an extraction end-to-end from the home entry point
5. Both tool screens have a "Back" or close action that returns to the home screen without restarting the app

**Plans:** 1 plan

Plans:
- [x] 07-01-PLAN.md — HomeFeature + HomeView + AppFeature enum routing + display name rename + human-verify

---

#### Phase 8: UX Redesign — 8-Bit Design System

**Goal:** Apply the GoProToolkit-8bit-system design language across all screens — beige background, black borders, monospace typography, pixel-aligned components, retro color palette, no gradients/shadows/blur. Progressive screenshot evaluation during implementation.

**Depends on:** Phase 7

**Requirements:**
- Design tokens file (colors, typography, spacing, component styles)
- All screens restyled: HomeView, FolderPickerView, ChunkReviewView, StitchProgressView, AudioFilePickerView, AudioExtractionView
- 8-bit button styles (black fill, 0 radius, 2px border, hover invert)
- Monospace typography throughout (JetBrains Mono)
- 4pt grid spacing system
- No gradients, shadows, blur, rounded corners
- Screenshot-driven evaluation at each screen

**Plans:** 0 plans

Plans:
- [ ] TBD (run /gsd:plan-phase 8 to break down)

---

## Progress

**Execution Order:** 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Testing Infrastructure | v1.0 | 2/2 | Complete | 2026-03-17 |
| 2. File Detection | v1.0 | 3/3 | Complete | 2026-03-17 |
| 3. Review, Preview & Reorder | v1.0 | 3/3 | Complete | 2026-03-18 |
| 4. Stitching & Archive | v1.0 | 3/3 | Complete | 2026-03-18 |
| 5. AudioExtractor Engine | v1.1 | 1/1 | Complete | 2026-03-18 |
| 6. Audio Extraction UI | v1.1 | 1/1 | Complete | 2026-03-18 |
| 7. Home Screen & App Rename | v1.1 | 1/1 | Complete | 2026-03-18 |
| 8. UX Redesign — 8-Bit Design System | v1.1 | 0/0 | Not started | - |

---

## Coverage Validation

**v1.0 Requirements (15 total — all complete):**

| Requirement | Phase | Status |
|-------------|-------|--------|
| TEST-01 | 1 | Complete |
| TEST-02 | 1 | Complete |
| TEST-03 | 1 | Complete |
| TEST-04 | 1 | Complete |
| DETECT-01 | 2 | Complete |
| DETECT-02 | 2 | Complete |
| DETECT-03 | 2 | Complete |
| DETECT-04 | 2 | Complete |
| ORDER-01 | 3 | Complete |
| ORDER-02 | 3 | Complete |
| ORDER-03 | 3 | Complete |
| ORDER-04 | 3 | Complete |
| STITCH-01 | 4 | Complete |
| STITCH-02 | 4 | Complete |
| STITCH-03 | 4 | Complete |

**v1.1 Requirements (14 total):**

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUDIO-02 | 5 | Pending |
| AUDIO-03 | 5 | Pending |
| AUDIO-06 | 5 | Pending |
| AUDIO-07 | 5 | Pending |
| TEST-05 | 5 | Pending |
| AUDIO-01 | 6 | Pending |
| AUDIO-04 | 6 | Pending |
| AUDIO-05 | 6 | Pending |
| TEST-06 | 6 | Pending |
| RENAME-01 | 7 | Pending |
| HOME-01 | 7 | Pending |
| HOME-02 | 7 | Pending |
| HOME-03 | 7 | Pending |
| HOME-04 | 7 | Pending |

**Coverage Summary:**
- v1.1 requirements: 14 total
- Mapped to phases: 14
- Unmapped: 0
- Coverage: 100% ✓

---

*Roadmap created: 2026-03-17*
*Roadmap revised (test-first): 2026-03-17*
*Roadmap updated (v1.1 milestone): 2026-03-18*
*Depth: quick (3-5 phases per milestone)*
*Next: `/gsd:execute-phase 6`*
