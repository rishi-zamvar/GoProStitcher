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
*Last updated: 2026-03-18*
