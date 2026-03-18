# Requirements: GoPro Toolkit

**Defined:** 2026-03-17
**Core Value:** A DJ/creator has a single app for all their GoPro post-processing needs — stitch chunks, extract audio, and future tools — without leaving the app or learning complex software.

## v1.0 Requirements (Complete)

### Testing Infrastructure

- [x] **TEST-01**: Unit test framework configured with test targets for logic, file I/O, and UI
- [x] **TEST-02**: Mock MP4 generator utility creates small test fixtures with valid MP4 headers and GoPro naming patterns
- [x] **TEST-03**: Test helpers for file system operations (temp directories, cleanup, validation)
- [x] **TEST-04**: CI-ready test runner (xcodebuild commands, test output parsing, failure reporting)

### File Detection

- [x] **DETECT-01**: User can select a folder via native macOS file picker dialog
- [x] **DETECT-02**: App validates folder contains .mp4 files; shows clear error if empty or no MP4s found
- [x] **DETECT-03**: App parses GoPro naming convention (GH/GX prefix, chapter/file number pattern) to determine correct stitch order
- [x] **DETECT-04**: App displays total file count and combined size before proceeding

### Review & Order

- [x] **ORDER-01**: App shows detected files in stitch order with video thumbnails
- [x] **ORDER-02**: User can play first few seconds of any clip for quick verification
- [x] **ORDER-03**: User can drag to reorder files if auto-detected order is wrong
- [x] **ORDER-04**: Each file shows duration, file size, and resolution metadata

### Stitching

- [x] **STITCH-01**: App stitches files by sequentially appending each chunk to file 1 in-place — no intermediate copies or file duplication
- [x] **STITCH-02**: Progress bar with text showing current phase and which file is being processed (e.g., "Stitching 3/7: GH030001.MP4")
- [x] **STITCH-03**: After stitching completes, each original chunk is individually zipped into an `archive/` subfolder at the source location

## v1.1 Requirements

### App Restructure

- [ ] **RENAME-01**: App renamed to "GoPro Toolkit" (display name, window title, bundle display name)
- [ ] **HOME-01**: Home screen with two big buttons: "Stitch Video" and "Extract Audio"
- [ ] **HOME-02**: Home screen layout is extensible — adding a third tool button requires minimal code change
- [ ] **HOME-03**: "Stitch Video" button launches existing stitch flow unchanged
- [ ] **HOME-04**: User can navigate back to home screen from any tool

### Audio Extraction

- [ ] **AUDIO-01**: User can select any MP4 file via native macOS file picker
- [ ] **AUDIO-02**: App extracts audio as 320kbps CBR MP3 using ffmpeg libmp3lame
- [ ] **AUDIO-03**: MP3 saved next to source file with same name and .mp3 extension
- [ ] **AUDIO-04**: Progress screen shows extraction status with metadata (source duration, file size, audio bitrate)
- [ ] **AUDIO-05**: On completion, MP3 is auto-revealed in Finder
- [ ] **AUDIO-06**: File collision handled — if .mp3 already exists, append suffix (e.g., `_1.mp3`)
- [ ] **AUDIO-07**: ffmpeg availability checked before extraction; clear error if not found

### Testing

- [ ] **TEST-05**: AudioExtractor engine unit tested (extraction, error cases, collision handling)
- [ ] **TEST-06**: Integration test covering full extraction pipeline (pick → extract → verify MP3)

## v2 Requirements

### Enhanced UX

- **UX-V2-01**: Batch mode — process multiple recording folders in sequence
- **UX-V2-02**: Recent folders history for quick re-access
- **UX-V2-03**: Drag-and-drop folder onto app icon to start
- **AUDIO-V2-01**: Batch multi-file audio extraction
- **AUDIO-V2-02**: Format selection (WAV, FLAC, AAC)
- **AUDIO-V2-03**: Source bitrate detection warning (don't upsample)
- **AUDIO-V2-04**: Smooth progress bar via ffmpeg stderr parsing

## Out of Scope

| Feature | Reason |
|---------|--------|
| Video editing/trimming/overlap detection | GoPro splits are exact — binary concat only |
| Multi-camera/session grouping | One recording per folder |
| Transcoding or re-encoding video | Preserves quality, saves time |
| iOS version | Desktop utility only |
| Cloud storage/sync | Purely local operations |
| Audio enhancement/normalization | Not an audio editor — extract as-is |
| Upsampling from lower bitrate | Misleading quality; anti-feature |

## Traceability

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

**Coverage:**
- v1.0 requirements: 15 total (all complete)
- v1.1 requirements: 14 total (14 mapped to phases 5-7)
- Unmapped: 0
- Coverage: 100% ✓

---
*Requirements defined: 2026-03-17*
*Updated: 2026-03-18 — v1.1 requirements mapped to phases 5-7*
