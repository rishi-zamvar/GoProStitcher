# GoPro Toolkit

## What This Is

A lightweight macOS desktop app for working with GoPro footage. Started as a stitcher for split MP4 chunks, now evolving into a multi-tool platform. Home screen presents independent tools as big buttons — designed to grow with new capabilities over time. Works with any MP4 but provides extra context for GoPro-named files.

## Core Value

A DJ/creator has a single app for all their GoPro post-processing needs — stitch chunks, extract audio, and future tools — without leaving the app or learning complex software.

## Current Milestone: v1.1 — Extract Audio + App Restructure

**Goal:** Rename to GoPro Toolkit, restructure UI as a tool launcher, add MP3 extraction from any MP4.

**Target features:**
- App renamed from GoProStitcher to GoPro Toolkit
- Home screen with two big buttons: "Stitch Video" | "Extract Audio"
- Extensible architecture for adding more tools later
- Extract Audio: file picker → select any MP4 → progress + metadata → 320kbps MP3 → auto-reveal in Finder

## Requirements

### Validated

- User picks a folder; app scans for GoPro MP4 chunks and shows count + size — v1.0
- App parses GoPro naming convention for correct stitch order — v1.0
- User reviews files with thumbnails, metadata, drag-to-reorder, preview modal — v1.0
- ffmpeg concat stitching with progress tracking and manifest archiving — v1.0
- Three-screen stitch flow: folder picker → review → progress — v1.0

### Active

- [ ] App renamed to GoPro Toolkit throughout (bundle ID, display name, window title)
- [ ] Home screen with extensible tool launcher (two big buttons for now)
- [ ] "Stitch Video" button launches existing stitch flow
- [ ] "Extract Audio" button launches new audio extraction flow
- [ ] User can pick any MP4 file via native file picker
- [ ] App shows extraction progress with metadata (duration, bitrate, file size)
- [ ] Audio extracted as 320kbps MP3 saved next to source file (same name, .mp3 extension)
- [ ] After extraction, MP3 auto-revealed in Finder
- [ ] Test suite built first — extraction engine tested before UI wiring

### Out of Scope

- Video editing, trimming, or overlap detection — not a video editor
- Multi-camera/multi-session grouping — one recording per folder for stitch
- iOS/iPhone version — macOS desktop only
- Cloud storage or sync — purely local operations
- Batch/multi-file audio extraction — one file at a time for v1.1
- Format selection (WAV, FLAC, AAC) — MP3 only for v1.1

## Context

- GoPro cameras use exFAT which limits files to ~4GB, splitting long recordings into sequential chunks
- Files are typically 12GB+ when stitched (3-4 chunks per recording)
- User is a DJ who records sets/events — needs this as a utility tool, not a production suite
- ffmpeg already a dependency (used for stitch) — reuse for audio extraction
- App uses TCA (Composable Architecture), xcodegen, swift-tools-version 5.9, macOS 13 deployment target
- Each tool should be an independent TCA feature module with its own reducer and view

## Constraints

- **Platform**: macOS desktop app, Swift/SwiftUI
- **Performance**: Must handle 12GB+ files without buffering entire file in memory
- **Architecture**: Each tool is an independent TCA module — no shared pipeline between tools
- **Dependencies**: ffmpeg required (already present from v1.0)
- **Testing**: Test-first — engine tests before UI wiring

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| ffmpeg concat with -c copy for stitching | Fast, no re-encoding, preserves quality | ✓ Good |
| Manifest JSON for reversion | Tiny file, enables undo without zip overhead | ✓ Good |
| TCA for state management | Testable, predictable, scales to multi-tool app | ✓ Good |
| xcodegen + project.yml | Regenerable, diff-friendly Xcode project | ✓ Good |
| Two big buttons home screen | Simple, extensible, clear entry points | — Pending |
| Independent tool modules | No coupling between stitch and extract | — Pending |
| ffmpeg for audio extraction | Already a dependency, handles all codecs | — Pending |

---
*Last updated: 2026-03-18 after v1.1 milestone start*
