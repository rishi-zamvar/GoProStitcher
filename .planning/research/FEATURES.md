# Feature Landscape: Audio Extraction + Multi-Tool Restructure (V1.1)

**Project:** GoPro Toolkit v1.1
**Context:** macOS app extending stitcher with audio extraction and multi-tool home screen
**Researched:** 2026-03-18
**Confidence:** HIGH (proven patterns from v1.0 + verified ffmpeg specifications)

---

## Executive Summary

V1.1 adds audio extraction (MP4 → 320kbps MP3) and restructures the app as a two-tool launcher. Both features are straightforward extensions of v1.0 patterns. Audio extraction follows the same process-based ffmpeg approach used in stitching. The home screen is standard TCA composition — no new architectural paradigms. Focus is on core functionality: extract reliably, save predictably, show progress. Power-user features (batch extraction, format selection, bitrate options) are deferred to post-MVP.

---

## Table Stakes

Features users expect. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Extract audio from any MP4 | User clicked "Extract Audio" button — they expect to extract | Low | ffmpeg with validated flags |
| Save MP3 next to source file | Creator expects output in same folder as input | Low | Simple filename logic (.mp3 extension) |
| Show progress while extracting | 30-60 second operation — user needs feedback | Low | Event-based: "started" → "complete" |
| Show duration before extraction | User verifies it's the right file | Low | AVMetadataReader (proven in v1.0) |
| Reveal MP3 in Finder after done | User wants quick access to result | Low | NSWorkspace.selectFile() one-liner |
| Clear error messages | Extraction fails (ffmpeg missing, bad file, disk full) | Low | Enum errors with localizedDescription |
| Home screen with two buttons | User wants to know "what can this app do?" | Low | Button routing to independent flows |

**Confidence:** HIGH — All proven in v1.0 stitch flow or industry standard.

---

## Differentiators

Features that set product apart. Not expected, but valued if included.

| Feature | Value Proposition | Complexity | When to Add |
|---------|-------------------|-----------|------------|
| Smooth progress bar (%) | User sees % complete during extraction | Medium | Post-V1.1 (requires ffmpeg stderr parsing) |
| Batch audio extraction | Extract multiple files without repeating picker | Medium | Post-V1.1 (async queue, UI redesign) |
| Audio bitrate selection | Power users choose 128, 192, 256, or 320kbps | Low-Med | Post-V1.1 (one bitrate keeps UI simple) |
| Format selection (WAV, FLAC, AAC) | Support lossless or alternative codecs | Medium-High | Post-V1.1 (each codec needs different flags) |
| Audio preview (play clip) | Quick listen before extracting | High | Post-V1.1 (requires AVAudioPlayer) |
| Source bitrate detection | Warn if source is lower than 320kbps target | Medium | Post-V1.1 (ffprobe analysis) |
| Estimated time remaining | User knows when extraction finishes | Low-Med | Post-V1.1 (basic calculation from duration) |

**Recommendation:** V1.1 ships core functionality only. Defer differentiators until post-MVP feedback. Audio extraction is NEW to the app; establish reliability first.

---

## Anti-Features

Features to explicitly NOT build. Common mistakes in audio extraction domain.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| VBR (Variable Bitrate) encoding | VBR produces 128-320k range; user expects "320kbps MP3" to mean exactly 320k | Use CBR (-b:a 320k); guarantees bitrate |
| "Auto-detect best bitrate" from source | Confusing when ffmpeg changes target bitrate without user knowing | Always extract to user-specified bitrate; log if source is lower |
| Batch extraction in V1.1 | Sounds good but adds async complexity, queue UI, per-file state management | Single-file extraction in V1.1; sequential is fine. Batch is post-MVP. |
| Metadata transfer from MP4 atoms | GoPro MP4 atoms don't map cleanly to MP3 ID3 tags; adds complexity | Extract audio only, preserve filename as reference. Metadata transfer is post-MVP. |
| Real-time settings changes mid-extraction | "Change bitrate while ffmpeg is running" — requires process restart | Lock settings before extraction starts; no mid-flight changes |
| Cloud file input (Dropbox, iCloud) | Scope creep: authentication, sync, network errors | Local files only. Users can sync to desktop first. |
| Video quality enhancement rumors | Don't promise audio quality improvements that transcoding can't deliver | Extract = copy with codec conversion. Enhancement is separate tool. |

**Principle:** Audio extraction is focused utility (MP4 → MP3). Don't build a full audio suite in V1.1.

---

## Feature Dependencies

```
Home Screen (entry point)
├── Stitch Tool (v1.0, unchanged)
│   └── folder picker → review → progress
│
└── Audio Tool (new in v1.1)
    ├── Requires: AudioExtractor core
    │   ├── ffmpeg subprocess management
    │   ├── File path validation
    │   └── Error handling
    ├── Requires: File picker (NSOpenPanel)
    ├── Requires: AVMetadataReader (duration display)
    └── Flow: picker → preview → extraction → reveal
```

**No circular dependencies.** Tools are independent. Both depend on Platform (Foundation, AVFoundation, Process).

---

## V1.1 Core Feature Set

### User Flow: Audio Extraction

```
1. Home Screen: User sees "Extract Audio" button
2. Clicks "Extract Audio"
3. File Picker: Selects any MP4
4. Preview Screen: Shows
   - File name
   - Duration (async-loaded)
   - File size
   - [Extract] button
5. Extraction Screen: Shows
   - Status: "Extracting..." → "Done!"
   - Destination path
   - [Open Result] button
6. Finder: MP3 auto-reveals
```

### Core Requirements

- [ ] **AUDIO-01:** User selects MP4 via native file picker
- [ ] **AUDIO-02:** App shows file duration before extraction starts
- [ ] **AUDIO-03:** App extracts audio as 320kbps MP3 using ffmpeg
- [ ] **AUDIO-04:** Output saved next to source: `video.mp4` → `video.mp3`
- [ ] **AUDIO-05:** Progress shown during extraction (event-based, not smooth)
- [ ] **AUDIO-06:** Finder auto-reveals MP3 file when complete
- [ ] **AUDIO-07:** Clear error messages for: ffmpeg missing, file not found, disk full, invalid file

### Home Screen Requirements

- [ ] **UI-01:** Home screen with two buttons: "Stitch Video" | "Extract Audio"
- [ ] **UI-02:** Button clicks launch respective tool flows
- [ ] **UI-03:** Tools are completely independent (no shared state)

### Test Coverage

- [ ] **TEST-AUDIO-01:** Unit test: AudioExtractor extracts MP3 from sample MP4
- [ ] **TEST-AUDIO-02:** Unit test: AudioExtractor error cases (file not found, ffmpeg missing)
- [ ] **TEST-AUDIO-03:** Integration test: Full flow (picker → preview → extract → reveal)
- [ ] **TEST-UI-01:** Integration test: Home screen routes to both tools correctly

**Total V1.1 Core Requirements: 14**

---

## What's Out of Scope for V1.1

| Feature | Why Deferred | Target Phase |
|---------|--------------|--------------|
| Smooth progress bar (% complete) | Requires ffmpeg stderr parsing; event-based sufficient | V1.2 |
| Bitrate selection UI | One bitrate (320k) keeps MVP simple; users can CLI if needed | V1.2 |
| Format selection (WAV, FLAC, AAC) | MP3 covers DJ/creator use case; adds test burden | V1.2 |
| Batch/multi-file extraction | Adds async complexity; sequential extraction works | V1.2 |
| Audio preview (play before extract) | Nice-to-have; not core to extraction | V1.2+ |
| Metadata transfer (ID3 tags from MP4) | GoPro metadata mapping is lossy; document as limitation | V1.2 |
| Extraction history/manifest | "What have I extracted?" — adds file tracking complexity | V1.2+ |

---

## Comparison with v1.0 Stitch (Reusable Patterns)

### Similarities (Code Reuse Opportunities)

| Element | Stitch (V1.0) | Audio (V1.1) | Reusable? |
|---------|---------------|-------------|-----------|
| File selection | NSOpenPanel for folder | NSOpenPanel for file | Pattern identical |
| Metadata preview | Show thumbnails, duration, size | Show duration, size | AVMetadataReader proven |
| Background process | ffmpeg concat | ffmpeg audio encode | Process API proven |
| Progress updates | Fire per-file completion | Fire on completion | Event-based pattern |
| Error handling | ChunkStitcherError enum | AudioExtractorError enum | Same error pattern |
| Result handling | Cleanup + manifest | Reveal in Finder | Different but straightforward |

### Differences (New Implementation)

| Element | Stitch | Audio | Impact |
|---------|--------|-------|--------|
| Input validation | Folder must have ≥2 MP4s with GoPro naming | Single MP4, any filename | Simpler validation |
| Output location | Overwrites chunk[0] in-place | Save as sibling (.mp3 extension) | Different file I/O |
| Archive strategy | Save stitch_manifest.json for reversion | No manifest needed | Simpler: extract once, keep original |
| ffmpeg codec | `-c copy` (no re-encoding) | `-acodec libmp3lame` (re-encode) | Different command flags |
| File cleanup | Delete original chunks after stitch | Keep original MP4 | Different lifecycle |

---

## MVP Feature Set: Focused & Testable

### Must Have (V1.1)

1. Extract MP4 → 320kbps MP3 (core value)
2. File picker for source selection (ease of use)
3. Show duration/size before extraction (user confidence)
4. Progress indication during extraction (user knows it's working)
5. Reveal result in Finder (quick access)
6. Clear error messages (reliability)
7. Home screen entry point (clear value proposition)

### Nice to Have (Deferred)

- Smooth progress bar (%)
- Bitrate selection UI
- Other audio formats
- Batch extraction
- Audio preview/playback
- Metadata preservation

### Why This Prioritization

1. Must-have features deliver core value: reliable, obvious, fast extraction
2. Nice-to-have features are optimizations for power users or competitive positioning
3. Audio extraction is NEW; ship it, gather user feedback, iterate
4. Focus over feature creep prevents shipping delays

---

## Testing Strategy

### Unit Tests (GoProStitcherKit Layer)

```swift
// AudioExtractor.swift tests
- testExtractValidMP4ToMP3() → verify .mp3 output exists, has audio
- testErrorHandling() → file not found, ffmpeg missing, invalid input
- testOutputPathLogic() → .mp4 → .mp3 filename derivation
- testCollisionDetection() → behavior when output file exists
```

### Integration Tests (App Layer)

```swift
// Full flow tests
- testAudioExtractionFlow() → picker → preview → extract → reveal
- testErrorMessageDisplay() → each error shows appropriate message
- testHomeScreenRouting() → both tool buttons work
- testAudioMetadataDisplay() → duration loads and displays
```

### Manual Testing

- Extract real GoPro footage (5+ test videos of varying lengths)
- Verify extracted MP3 plays in Finder Quick Look
- Verify bitrate is 320kbps using `ffprobe` or `mediainfo` tool
- Test on non-GoPro MP4s (iPhone, etc.) — app supports any MP4
- Error testing: corrupt MP4, missing ffmpeg, full disk

---

## Feature Complexity & Effort Estimates

| Feature | Code Lines | Testing Hours | Risk |
|---------|------------|---------------|------|
| AudioExtractor core | ~200 | 2 | LOW (proven pattern) |
| Audio extraction UI (3 screens) | ~400 | 3 | LOW (mirrors stitch flow) |
| Home screen + restructure | ~200 | 2 | LOW (standard TCA) |
| File picker (reuse) | ~100 | 1 | LOW (identical to folder picker) |
| **Total** | **~900** | **8** | **LOW** |

**Estimate:** 4-7 days development (aggressive: 4 days; comfortable: 6 days)

---

## Known Pitfalls in Audio Extraction Domain

| Pitfall | Impact | Prevention |
|---------|--------|-----------|
| ffmpeg subprocess hangs on corrupted MP4 | User thinks app froze | Set process timeout (10 minutes); fail gracefully |
| Output file overwrites without warning | User loses previous extraction | Check path exists before starting; ask before overwrite |
| Large files (12GB+) show no progress | User thinks app stalled | Show "Extracting..." status every N seconds |
| ffmpeg not installed on user machine | App crashes on first extract | Detect at launch, show helpful install message (mirrors v1.0) |
| MP3 bitrate doesn't match target (320k) | User expects "320kbps" to mean exactly 320k | Use CBR mode (-b:a 320k), not VBR |

---

## Competitive Context

### What Others Do

| Tool | Strength |
|------|----------|
| HandBrake | Batch processing, hardware acceleration |
| Audacity | Post-extract editing, visual waveform |
| MediaHuman Audio Converter | Bulk extraction, format options |

### Where We Differentiate (v1.1)

- **Native macOS:** Auto-reveal in Finder (vs. manual folder navigation)
- **DJ/Creator Defaults:** 320kbps MP3, extraction next to source
- **Dual Tools:** Single app for stitching AND audio extraction (unique for GoPro users)
- **Lightweight:** No bloat; focused on core task

---

## Sources & References

### Stack Specifications
- `.planning/research/STACK.md` — Exact ffmpeg flags, technical decisions, no new dependencies

### V1.0 Reference Implementation
- `GoProStitcherKit/Sources/GoProStitcherKit/ChunkStitcher.swift` — Process-based ffmpeg pattern
- `GoProStitcher/Features/StitchProgress/StitchProgressFeature.swift` — TCA reducer structure
- `GoProStitcher/Features/FolderPicker/FolderPickerFeature.swift` — File picker pattern

### FFmpeg Documentation
- [Encode/MP3 – FFmpeg Wiki](https://trac.ffmpeg.org/wiki/Encode/MP3)
- [FFmpeg Codecs Documentation](https://ffmpeg.org/ffmpeg-codecs.html)

---

**Summary:** V1.1 audio extraction is well-scoped, low-risk, and leverages proven v1.0 patterns. Focus on core (extract, save, reveal); defer power-user features to post-MVP. Ship it, learn from users, iterate.

Last updated: 2026-03-18
