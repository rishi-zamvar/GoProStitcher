# Requirements: GoPro Toolkit

**Defined:** 2026-03-17
**Core Value:** A DJ/creator has a single app for all their GoPro post-processing needs — stitch chunks, extract audio, downscale video, and future tools — without leaving the app or learning complex software.

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
- [x] **STITCH-02**: Progress bar with text showing current phase and which file is being processed
- [x] **STITCH-03**: After stitching completes, each original chunk is individually zipped into an `archive/` subfolder at the source location

## v1.1 Requirements (Complete)

### App Restructure

- [x] **RENAME-01**: App renamed to "GoPro Toolkit" (display name, window title, bundle display name)
- [x] **HOME-01**: Home screen with two big buttons: "Stitch Video" and "Extract Audio"
- [x] **HOME-02**: Home screen layout is extensible — adding a third tool button requires minimal code change
- [x] **HOME-03**: "Stitch Video" button launches existing stitch flow unchanged
- [x] **HOME-04**: User can navigate back to home screen from any tool

### Audio Extraction

- [x] **AUDIO-01**: User can select any MP4 file via native macOS file picker
- [x] **AUDIO-02**: App extracts audio as 320kbps CBR MP3 using ffmpeg libmp3lame
- [x] **AUDIO-03**: MP3 saved next to source file with same name and .mp3 extension
- [x] **AUDIO-04**: Progress screen shows extraction status with metadata (source duration, file size, audio bitrate)
- [x] **AUDIO-05**: On completion, MP3 is auto-revealed in Finder
- [x] **AUDIO-06**: File collision handled — if .mp3 already exists, append suffix
- [x] **AUDIO-07**: ffmpeg availability checked before extraction; clear error if not found

### Testing

- [x] **TEST-05**: AudioExtractor engine unit tested (extraction, error cases, collision handling)
- [x] **TEST-06**: Integration test covering full extraction pipeline

## v1.2 Requirements

### Video Downscale Engine

- [ ] **DOWNSCALE-01**: VideoDownscaler engine re-encodes video to H.264 1080p (`-vf scale=-2:1080 -c:v libx264`)
- [ ] **DOWNSCALE-02**: Audio stream copied untouched (`-c:a copy`) — zero quality loss
- [ ] **DOWNSCALE-03**: Output filename defaults to `source_1080p.mp4`, collision handled with `_1`, `_2` suffixes
- [ ] **DOWNSCALE-04**: ffmpeg availability checked before encoding; clear error if not found
- [ ] **DOWNSCALE-05**: Progress reported via ffmpeg `-progress pipe:1` with percentage and time tracking

### Video Downscale UI

- [ ] **DOWNSCALE-06**: User can select any MP4 via native file picker
- [ ] **DOWNSCALE-07**: Metadata summary shown before encoding (source resolution, file size, duration, codec)
- [ ] **DOWNSCALE-08**: Editable output filename field with default `source_1080p.mp4`
- [ ] **DOWNSCALE-09**: Progress screen shows RetroProgressBar with percentage + time elapsed
- [ ] **DOWNSCALE-10**: On completion, output auto-revealed in Finder

### Integration

- [ ] **HOME-05**: "Downscale Video" button on home screen as third tool
- [ ] **HOME-06**: Back-to-home navigation from downscale flow

### Testing

- [ ] **TEST-07**: VideoDownscaler engine unit tested (encoding, audio copy, collision, error paths)
- [ ] **TEST-08**: Integration test covering full downscale pipeline (pick → encode → verify 1080p output)

### Design

- [ ] **DESIGN-01**: All downscale UI screens use 8-bit design tokens (RetroCard, RetroButton, RetroProgressBar, RetroFont)

## v2 Requirements

### Enhanced UX

- **UX-V2-01**: Batch mode — process multiple recording folders in sequence
- **UX-V2-02**: Recent folders history for quick re-access
- **UX-V2-03**: Drag-and-drop folder onto app icon to start
- **AUDIO-V2-01**: Batch multi-file audio extraction
- **AUDIO-V2-02**: Format selection (WAV, FLAC, AAC)
- **DOWNSCALE-V2-01**: Resolution presets (720p, 480p)
- **DOWNSCALE-V2-02**: Batch video downscaling
- **DOWNSCALE-V2-03**: Custom resolution input

## Out of Scope

| Feature | Reason |
|---------|--------|
| Video editing/trimming | Not a video editor |
| Multi-camera/session grouping | One recording per folder |
| iOS version | Desktop utility only |
| Cloud storage/sync | Purely local operations |
| Audio enhancement/normalization | Not an audio editor |
| Upsampling video resolution | Misleading quality; anti-feature |
| Re-encoding audio during downscale | -c:a copy preserves fidelity |

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
| AUDIO-02 | 5 | Complete |
| AUDIO-03 | 5 | Complete |
| AUDIO-06 | 5 | Complete |
| AUDIO-07 | 5 | Complete |
| TEST-05 | 5 | Complete |
| AUDIO-01 | 6 | Complete |
| AUDIO-04 | 6 | Complete |
| AUDIO-05 | 6 | Complete |
| TEST-06 | 6 | Complete |
| RENAME-01 | 7 | Complete |
| HOME-01 | 7 | Complete |
| HOME-02 | 7 | Complete |
| HOME-03 | 7 | Complete |
| HOME-04 | 7 | Complete |
| DOWNSCALE-01 | 9 | Complete |
| DOWNSCALE-02 | 9 | Complete |
| DOWNSCALE-03 | 9 | Complete |
| DOWNSCALE-04 | 9 | Complete |
| DOWNSCALE-05 | 9 | Complete |
| TEST-07 | 9 | Complete |
| DOWNSCALE-06 | 10 | Pending |
| DOWNSCALE-07 | 10 | Pending |
| DOWNSCALE-08 | 10 | Pending |
| DOWNSCALE-09 | 10 | Pending |
| DOWNSCALE-10 | 10 | Pending |
| HOME-05 | 10 | Pending |
| HOME-06 | 10 | Pending |
| TEST-08 | 10 | Pending |
| DESIGN-01 | 10 | Pending |

**Coverage:**
- v1.0 requirements: 15 total (all complete)
- v1.1 requirements: 14 total (all complete)
- v1.2 requirements: 15 total (mapped to phases 9-10)
- Unmapped: 0
- Coverage: 100% ✓

---
*Requirements defined: 2026-03-17*
*Updated: 2026-03-18 — v1.2 requirements defined*
*Updated: 2026-03-18 — v1.2 traceability mapped (phases 9-10)*
