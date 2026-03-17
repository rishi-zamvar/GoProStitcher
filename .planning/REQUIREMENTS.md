# Requirements: GoProStitcher

**Defined:** 2026-03-17
**Core Value:** A DJ/creator can go from a folder of split GoPro chunks to a single continuous video file with minimal disk usage, no file duplication, and confidence that originals are safely archived.

## v1 Requirements

### Testing Infrastructure

- [ ] **TEST-01**: Unit test framework configured with test targets for logic, file I/O, and UI
- [ ] **TEST-02**: Mock MP4 generator utility creates small test fixtures with valid MP4 headers and GoPro naming patterns
- [ ] **TEST-03**: Test helpers for file system operations (temp directories, cleanup, validation)
- [ ] **TEST-04**: CI-ready test runner (xcodebuild commands, test output parsing, failure reporting)

### File Detection

- [ ] **DETECT-01**: User can select a folder via native macOS file picker dialog
- [ ] **DETECT-02**: App validates folder contains .mp4 files; shows clear error if empty or no MP4s found
- [ ] **DETECT-03**: App parses GoPro naming convention (GH/GX prefix, chapter/file number pattern) to determine correct stitch order
- [ ] **DETECT-04**: App displays total file count and combined size before proceeding

### Review & Order

- [ ] **ORDER-01**: App shows detected files in stitch order with video thumbnails
- [ ] **ORDER-02**: User can play first few seconds of any clip for quick verification
- [ ] **ORDER-03**: User can drag to reorder files if auto-detected order is wrong
- [ ] **ORDER-04**: Each file shows duration, file size, and resolution metadata

### Stitching

- [ ] **STITCH-01**: App stitches files by sequentially appending each chunk to file 1 in-place — no intermediate copies or file duplication
- [ ] **STITCH-02**: Progress bar with text showing current phase and which file is being processed (e.g., "Stitching 3/7: GH030001.MP4")
- [ ] **STITCH-03**: After stitching completes, each original chunk is individually zipped into an `archive/` subfolder at the source location

## v2 Requirements

### Enhanced UX

- **UX-V2-01**: Batch mode — process multiple recording folders in sequence
- **UX-V2-02**: Recent folders history for quick re-access
- **UX-V2-03**: Drag-and-drop folder onto app icon to start

## Out of Scope

| Feature | Reason |
|---------|--------|
| Video editing/trimming/overlap detection | GoPro splits are exact — binary concat only |
| Multi-camera/session grouping | One recording per folder |
| Transcoding or re-encoding | Preserves quality, saves time |
| iOS version | Desktop utility only |
| Cloud storage/sync | Purely local operations |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TEST-01 | 1 | Pending |
| TEST-02 | 1 | Pending |
| TEST-03 | 1 | Pending |
| TEST-04 | 1 | Pending |
| DETECT-01 | 2 | Pending |
| DETECT-02 | 2 | Pending |
| DETECT-03 | 2 | Pending |
| DETECT-04 | 2 | Pending |
| ORDER-01 | 3 | Pending |
| ORDER-02 | 3 | Pending |
| ORDER-03 | 3 | Pending |
| ORDER-04 | 3 | Pending |
| STITCH-01 | 4 | Pending |
| STITCH-02 | 4 | Pending |
| STITCH-03 | 4 | Pending |

**Coverage:**
- v1 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0
- **Coverage: 100% ✓**

---
*Requirements defined: 2026-03-17*
*Traceability updated: 2026-03-17 after roadmap creation*
*Traceability revised (test-first): 2026-03-17 after roadmap revision*
