# Milestones: GoPro Toolkit

## v1.0 — GoPro Stitcher (Complete)

**Completed:** 2026-03-18
**Phases:** 1-4

**What shipped:**
- Folder picker with GoPro file detection (GH/GX naming patterns)
- Review screen: thumbnails, metadata (duration/size/resolution), drag-to-reorder, preview modal
- ffmpeg concat demuxer stitching with progress tracking
- Manifest-based archiving for reversion (stitch_manifest.json)
- Source chunk cleanup after stitch
- Three-screen UI: folder picker → review/reorder/preview → stitch progress

**Requirements delivered:** 15/15 (TEST-01..04, DETECT-01..04, ORDER-01..04, STITCH-01..03)

**Key decisions:**
- ffmpeg concat demuxer with -c copy (no re-encoding)
- TCA (Composable Architecture) for state management
- xcodegen + project.yml as project source-of-truth
- Manifest JSON for reversion instead of zip archiving
- swift-tools-version 5.9, macOS 13 deployment target

---

## v1.1 — GoPro Toolkit (Complete)

**Completed:** 2026-03-18
**Phases:** 5-8

**What shipped:**
- Audio extraction: MP4 → 320kbps MP3 via ffmpeg libmp3lame with progress tracking
- Home screen: two-tool launcher with extensible ToolDescriptor array
- App renamed to "GoPro Toolkit" (display name, window title)
- 8-bit design system: JetBrains Mono font, 6-color retro palette, block-fill progress bars, hard-edge cards, no gradients/shadows/blur
- Pixel-art app icon
- Back-to-home navigation from all tool screens
- Design token compliance tests

**Requirements delivered:** 14/14 (RENAME-01, HOME-01..04, AUDIO-01..07, TEST-05..06)

**Key decisions:**
- ffmpeg for audio extraction (zero new SPM deps)
- ActiveTool enum for tool routing (not Bool flags)
- JetBrains Mono bundled, ATSApplicationFontsPath = "."
- RetroProgressBar block-fill (████░░░░) replacing system ProgressView
- DesignTokenComplianceTests for regression guard

---
*Last updated: 2026-03-18*
