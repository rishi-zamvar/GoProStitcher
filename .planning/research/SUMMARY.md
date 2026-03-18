# Research Summary: GoPro Toolkit v1.1

**Project:** GoPro Toolkit v1.1
**Domain:** macOS desktop audio/video utility
**Researched:** 2026-03-18
**Confidence:** HIGH (leverages proven v1.0 patterns + verified ffmpeg specifications)

---

## Executive Summary

V1.1 adds audio extraction (MP4 → 320kbps MP3) and restructures the app as a two-tool launcher. Both features are low-risk, straightforward extensions of v1.0 patterns. The technology stack requires zero new SPM dependencies — the existing ffmpeg approach (Process-based subprocess) proven in v1.0 stitching applies directly to audio extraction. The UI restructure uses standard TCA composition: home screen routes to independent tool flows (stitch unchanged, new audio extraction). The primary technical focus is reliable error handling and clear user feedback — particularly preventing ffmpeg availability issues (Pitfall 1) and avoiding silent file overwrites (Pitfall 2). With disciplined implementation of the pitfall mitigations outlined in research, v1.1 ships focused, low-complexity functionality.

---

## Key Findings

### Recommended Stack

Zero new dependencies. The existing stack (Foundation, AppKit, AVFoundation, TCA, ffmpeg) provides everything needed:

- **ffmpeg subprocess (Process API):** Already proven in v1.0 ChunkStitcher; same approach for audio extraction. No SwiftFFmpeg wrapper needed — Foundation Process is simpler and more maintainable.
- **Audio codec:** libmp3lame (LAME MP3 encoder) via ffmpeg's `-acodec libmp3lame` flag. Industry standard, ships with ffmpeg.
- **Bitrate mode:** CBR (Constant Bitrate) `-b:a 320k`. Guarantees exactly 320kbps output; simpler to document than VBR; matches DJ/creator use case (not a batch processor).
- **Metadata extraction:** AVFoundation's AVMetadataReader (already in codebase) for duration display pre-extraction.
- **TCA patterns:** Identical three-screen flow pattern as stitch: file picker → metadata preview → progress.

**Key decision:** Simple ffmpeg command (no smooth progress parsing initially) — sufficient for 30-60 second extraction, defers smooth progress bar to post-MVP.

**Installation:** ffmpeg must be installed via `brew install ffmpeg`. Recommend pre-flight detection at app launch (v1.0 ChunkStitcher already does this).

**See:** `.planning/research/STACK.md` for complete specifications including exact ffmpeg command-line flags.

### Expected Features

**Must have (table stakes):**
- Extract audio from any MP4 as 320kbps MP3 (core value proposition)
- File picker for MP4 selection (ease of use)
- Show duration/size before extraction (user confidence)
- Progress indication during extraction (user knows it's working — at minimum "Extracting..." status)
- Save MP3 next to source MP4 (predictable output location)
- Reveal MP3 in Finder after completion (quick access)
- Clear error messages (ffmpeg missing, file not found, disk full, invalid file)
- Home screen with two buttons: "Stitch Video" | "Extract Audio" (clear value proposition)

**Should have (post-v1.1 differentiators):**
- Smooth progress bar (%) — deferred because requires ffmpeg stderr parsing
- Bitrate selection UI — one bitrate (320k) keeps MVP simple
- Batch extraction — adds async complexity, sequential is fine for v1.1
- Audio format selection (WAV, FLAC, AAC) — MP3 covers DJ/creator case; adds test burden
- Audio preview/playback — nice-to-have, not core to extraction

**See:** `.planning/research/FEATURES.md` for complete feature scope, anti-features to avoid, and testing strategy.

### Architecture Approach

Straightforward TCA composition with no new architectural paradigms. App transitions from single-flow to multi-tool launcher:

- **AppFeature (root):** Routes between home screen and active tools (stitch or audio). Tools are optional state; only one active at a time.
- **HomeScreenFeature (new):** Displays two buttons; delegates to AppFeature for routing. ~20 lines, pure presentation.
- **StitchFlowFeature (refactored from v1.0 AppFeature):** Wraps existing folder picker → review → progress flow. No internal changes; just moved one level up in hierarchy.
- **AudioFlowFeature (new):** Independent flow mirror: file picker → preview → extraction progress. Uses same event-based pattern as stitch.

**Critical principle:** Tools have completely independent state — zero shared fields. Each tool feature is self-contained, testable in isolation. This prevents the state entanglement pitfall (Pitfall 5) and scales to future tools.

**See:** `.planning/research/ARCHITECTURE.md` for detailed component diagrams, data flow scenarios, migration path from v1.0, and testing strategy.

### Critical Pitfalls to Prevent

1. **ffmpeg Not Installed (Pitfall 1 — CRITICAL):** User clicks "Extract Audio", gets cryptic error, uninstalls app. Prevention: Detect ffmpeg at app launch via standard paths; show helpful error with installation instructions if missing. v1.0 ChunkStitcher already does this — apply same pattern.

2. **Silent File Overwrite (Pitfall 2 — CRITICAL):** User extracts same file twice; ffmpeg silently overwrites MP3. Prevention: Check output path exists before extraction; show dialog ("Replace?", "Cancel", "Save As..."). Standard pattern (matches Word, Finder).

3. **Extraction Appears to Hang (Pitfall 3 — HIGH):** User selects 2GB MP4, no UI feedback for 60 seconds, force-quits app. Prevention: Show "Extracting..." status immediately (within 100ms); update every 5-10 seconds even if just "still extracting". Add 10-minute timeout safety valve.

4. **CBR vs. VBR Confusion (Pitfall 4 — HIGH):** Developer uses VBR flags by mistake; output bitrate varies 180-280k. User expects "320kbps" to mean exactly 320k. Prevention: Use verified flags from STACK.md (`-b:a 320k` only, never `-qscale:a`); add code comment explaining CBR vs. VBR; unit test bitrate with ffprobe.

5. **Tool State Entanglement (Pitfall 5 — HIGH):** Both tools share progress state; state management becomes fragile. Prevention: Enforce architectural principle: each tool has completely independent state struct. Non-negotiable. Code review and tests verify isolation.

**See:** `.planning/research/PITFALLS.md` for detailed prevention strategies, phase-specific warnings, and validation checklist for QA.

---

## Implications for Roadmap

### Suggested Phase Structure

Research recommends a three-phase approach based on dependencies and risk:

#### Phase 1: AudioExtractor Core (Kit Layer)
**Rationale:** Establish foundation API before UI. Testable in isolation; no UI complexity.

**Delivers:**
- AudioExtractor.swift (extract method with verified ffmpeg flags)
- AudioExtractorError.swift (public error enum with LocalizedError)
- Unit tests verifying MP3 extraction and bitrate accuracy
- ffmpeg availability check at app launch (with helpful error message)
- Pre-flight validation: input readable, output writable, disk space available

**Technical foundation:**
- Implements from ARCHITECTURE.md: Kit-layer module pattern (mirrors ChunkStitcher)
- Uses from STACK.md: Exact ffmpeg flags, Process API pattern
- Prevents from PITFALLS.md: Pitfall 4 (CBR bitrate verification in unit tests), Pitfall 6 (proper error exit code checking), Pitfall 1 (ffmpeg availability detection)

**Estimated effort:** ~200 lines of code, 2-3 hours development + 2 hours testing

---

#### Phase 2: Audio Extraction UI Flow
**Rationale:** Build UI on top of proven core API. Implements three screens using TCA patterns proven in v1.0.

**Delivers:**
- AudioFilePickerFeature (NSOpenPanel for source MP4 selection)
- AudioPreviewFeature (show duration, size, filename before extraction)
- AudioExtractionProgressFeature (show status, reveal in Finder on completion)
- Integration tests for full flow (picker → preview → extract → reveal)

**Technical implementation:**
- Implements from ARCHITECTURE.md: AudioFlowFeature coordinator, TCA three-screen pattern, event-based progress callback
- Uses from STACK.md: Progress tracking approach (event-based "started"/"completed")
- Prevents from PITFALLS.md: Pitfall 3 (immediate "Extracting..." feedback, periodic updates), Pitfall 2 (output collision detection with user dialog), Pitfall 7 (use Foundation URL APIs for path derivation), Pitfall 9 (pre-flight output directory validation)

**Estimated effort:** ~400 lines of UI code, 3 hours development + 3 hours testing/polish

---

#### Phase 3: Home Screen + Navigation Restructure
**Rationale:** Integrate audio flow into app. Restructure root navigation. Tests multi-tool coordination.

**Delivers:**
- HomeScreenFeature (two buttons for tool selection)
- Updated AppFeature (routes to either stitch or audio flow, handles back button)
- Refactored StitchFlowFeature (wraps v1.0 logic without changes)
- Integration tests: home → stitch and home → audio both work correctly
- Back button clears tool state, returns home
- Update app display name to "GoPro Toolkit" (from "GoPro Stitcher")

**Technical implementation:**
- Implements from ARCHITECTURE.md: AppFeature root reducer with optional tool flows, Scope/ifLet pattern for navigation
- No new stack elements needed (all composition)
- Prevents from PITFALLS.md: Pitfall 5 (enforce independent state structs; code review)

**Estimated effort:** ~200 lines, 2 hours development + 2 hours integration testing

---

### Phase Ordering Rationale

1. **Core API first:** AudioExtractor is the technical foundation. Must be correct (especially bitrate, error handling) before UI is built. Testable in isolation.

2. **UI on proven API:** Three-screen flow is standard TCA pattern. Building on proven core API reduces risk. Each screen is straightforward:
   - Picker: copy FolderPickerFeature pattern (swap folder for file)
   - Preview: copy ChunkReviewFeature pattern (show metadata, user confirms)
   - Progress: copy StitchProgressFeature pattern (show status, reveal result)

3. **Navigation last:** Home screen and AppFeature restructure are highest-level changes. By this point, both tools work independently. Restructure just routes between them.

**Why not parallel phases?** UI depends on core API working correctly (especially error handling). Pitfall 6 (process failures) must be solved in Phase 1 to avoid building fragile UI on top of buggy core.

---

### Research Flags

**Phases needing deeper research during planning:**
- **Phase 1, Pitfall 1 (ffmpeg availability):** Quick research: Verify v1.0 ChunkStitcher implementation for ffmpeg check pattern; copy approach. ~15 minutes.
- **Phase 2, Pitfall 3 (progress feedback):** Decide: Simple event-based ("Extracting...", "Done") vs. smooth % progress. STACK.md recommends simple. If planning team wants smooth, research ffmpeg stderr parsing. ~30 minutes if needed.

**Phases with standard patterns (skip deep research):**
- **Phase 1, core implementation:** FFmpeg specifications are final (documented in STACK.md with full command-line flags). TCA error pattern proven in v1.0.
- **Phase 2, UI screens:** All three screens mirror v1.0 patterns (FolderPickerFeature, ChunkReviewFeature, StitchProgressFeature). Implementation follows established TCA composition rules.
- **Phase 3, navigation:** Standard TCA root reducer with optional child flows. Multiple tutorials, proven in community.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| **Stack** | HIGH | ffmpeg command-line flags verified against FFmpeg documentation. Process API pattern proven in v1.0 ChunkStitcher. Zero new SPM dependencies. No unknowns. |
| **Features** | HIGH | MVP scope clearly defined in FEATURES.md with table stakes vs. differentiators vs. deferred clearly separated. All must-haves are straightforward to implement. |
| **Architecture** | HIGH | TCA composition patterns well-established in v1.0. HomeScreen/AppFeature/tool flows are standard Redux-like reducers. No novel patterns required. |
| **Pitfalls** | HIGH | Research identified 10 specific pitfalls with prevention strategies. Pitfalls 1-5 are CRITICAL; prevention strategies are concrete and testable. All pitfall mitigations have precedent in v1.0 or are standard domain practices. |

**Overall confidence: HIGH**

All four research areas are well-understood with minimal uncertainty. Technology is proven (ffmpeg + TCA). Architecture patterns are standard. Pitfalls are specific and preventable. No research blockers for roadmap creation.

### Gaps to Address

**No major gaps identified.** Minor clarifications to validate during planning:

1. **Smooth progress bar (Phase 2 design decision):** Research recommends event-based ("Extracting..." status) for v1.1 MVP. Clarify with planning/design: is event-based acceptable, or must smooth % progress be in v1.1? If smooth required, estimate stderr parsing complexity during Phase 2 planning.

2. **macOS version compatibility:** STACK.md specifies macOS 13.0+. Confirm no audio extraction edge cases on Intel vs. Apple Silicon. Validate during Phase 1 testing.

3. **Test coverage on real GoPro footage:** STACK.md and PITFALLS.md recommend testing with actual 30-min GoPro MP4s. Ensure test resources include real footage, not just synthetic files.

---

## Sources

### Primary (HIGH confidence)
- **FFmpeg Encode/MP3 Wiki** — Command-line flags, CBR vs. VBR comparison, LAME encoder documentation
- **FFmpeg Codecs Documentation** — libmp3lame options (bitrate, quality levels)
- **v1.0 GoProStitcher implementation** — ChunkStitcher.swift (Process pattern), ChunkReviewFeature.swift (TCA reducer structure), FolderPickerFeature.swift (file picker pattern)
- **TCA Composable Architecture documentation** — Scope, ifLet, Reduce patterns for multi-tool navigation

### Secondary (MEDIUM confidence)
- **FFmpeg Audio Extraction Best Practices** — Shotstack, OTTVerse guides confirming CBR approach and command syntax
- **Swift Forums:** Process-based subprocess management patterns
- **Foundation documentation:** URL API for safe path manipulation, FileManager for validation

### Tertiary (domain experience)
- **macOS desktop app pitfalls:** Error message clarity, progress feedback, file I/O edge cases
- **v1.0 lessons learned:** ffmpeg subprocess reliability, error handling patterns

---

*Research completed: 2026-03-18*
*Ready for roadmap: YES*

**Next step:** Roadmap creation will structure v1.1 milestone using Phase 1 → Phase 2 → Phase 3 sequence above, with research flag for smooth progress bar decision (Phase 2), and pitfall validation checklist for QA.
