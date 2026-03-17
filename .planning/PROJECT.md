# GoProStitcher

## What This Is

A lightweight macOS desktop app that reassembles split GoPro MP4 recordings. GoPro cameras split long recordings into ~4GB chunks due to exFAT filesystem limitations — this tool detects the chunks in a folder, lets you verify order with quick preview, then stitches them sequentially by appending each chunk to the first file in-place. After stitching, originals are individually zipped into an archive subfolder.

## Core Value

A DJ/creator can go from a folder of split GoPro chunks to a single continuous video file with minimal disk usage, no file duplication, and confidence that originals are safely archived.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] User picks a folder on their Mac; app scans for .mp4 files and confirms footage exists
- [ ] App detects GoPro naming convention and determines correct stitch order via fuzzy pattern matching
- [ ] User reviews detected file order with quick-preview playback (first few seconds of each clip)
- [ ] User can reorder files manually if auto-detected order is wrong
- [ ] App stitches files sequentially: appends file 2 to file 1 in-place, then file 3, etc. — no duplication of large files
- [ ] Stitching is iterative (one file at a time) so user can troubleshoot between steps
- [ ] Progress bar with text showing exactly which phase/file is being processed
- [ ] After stitching, original chunk files are individually zipped into an `archive/` subfolder at the same location
- [ ] Lightweight three-screen UI: folder picker → review/reorder/preview → stitch progress

### Out of Scope

- Video editing, trimming, or overlap detection — chunks are perfectly split by GoPro, just concatenate
- Multi-camera/multi-session grouping — folder contains one recording's chunks only
- Transcoding or re-encoding — binary append, no quality loss
- iOS/iPhone version — macOS desktop only
- Cloud storage or sync — purely local file operations

## Context

- GoPro cameras use exFAT which limits files to ~4GB, splitting long recordings into sequential chunks
- Files are typically 12GB+ when stitched (3-4 chunks per recording)
- GoPro naming convention uses a pattern like GH010001.MP4, GH020001.MP4 (incrementing chapter number) — fuzzy matching needed
- In-place append avoids doubling disk usage (critical when dealing with 12GB+ files)
- User is a DJ who records sets/events — needs this as a utility tool, not a production suite
- Quick preview means "play first few seconds to verify it's the right clip" — no full playback controls needed

## Constraints

- **Platform**: macOS desktop app, Swift/SwiftUI
- **Performance**: Must handle 12GB+ files without duplicating them in memory or on disk
- **Stitching method**: Sequential binary append to first file (no intermediate copies)
- **UI**: Minimal — three screens, no complex navigation
- **Compression**: Individual zip per chunk file into archive/ subfolder

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| In-place append to file 1 | Avoids duplicating 12GB+ files; saves disk and time | — Pending |
| Individual zip per chunk (not one big archive) | Easier to find/extract specific chunks if needed | — Pending |
| No re-encoding | GoPro chunks are perfectly split; binary concat preserves quality with zero processing time | — Pending |

---
*Last updated: 2026-03-17 after initialization*
