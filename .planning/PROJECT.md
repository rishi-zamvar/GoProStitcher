# GoPro Toolkit

## What This Is

A lightweight macOS desktop app for working with GoPro footage. Multi-tool platform with an 8-bit retro design system. Home screen presents independent tools as big buttons — designed to grow with new capabilities. Works with any MP4 but provides extra context for GoPro-named files.

## Core Value

A DJ/creator has a single app for all their GoPro post-processing needs — stitch chunks, extract audio, downscale video, and future tools — without leaving the app or learning complex software.

## Current Milestone: v1.2 — Video Downscale

**Goal:** Add a "Downscale Video" tool that converts 4K MP4 to 1080p H.264 while copying audio untouched.

**Target features:**
- "Downscale Video" button on home screen (third tool)
- Pick MP4 → metadata summary → editable output name (default: source_1080p.mp4) → progress → auto-reveal in Finder
- Video re-encoded to H.264 1080p (-vf scale=-2:1080 -c:v libx264)
- Audio stream copied untouched (-c:a copy) for maximum fidelity
- Full test suite built first ensuring integration is solid
- Same 8-bit design language throughout

## Requirements

### Validated

- Folder picker with GoPro file detection, review/reorder, preview modal — v1.0
- ffmpeg concat stitching with progress tracking and manifest archiving — v1.0
- Audio extraction: MP4 → 320kbps MP3, progress tracking, Finder reveal — v1.1
- Home screen with extensible tool launcher — v1.1
- App renamed to "GoPro Toolkit" — v1.1
- 8-bit design system: JetBrains Mono, retro palette, block-fill progress, hard-edge cards — v1.1

### Active

- [ ] "Downscale Video" button on home screen as third tool entry
- [ ] User picks any MP4 via file picker
- [ ] Metadata summary shown before encoding (source resolution, size, duration, codec)
- [ ] Editable output filename (default: source_1080p.mp4)
- [ ] Video re-encoded to H.264 1080p with audio stream copied untouched
- [ ] Progress bar with percentage and time tracking during encoding
- [ ] Output auto-revealed in Finder on completion
- [ ] Full test suite built first — engine + integration tests before UI
- [ ] All UI in 8-bit design language (RetroCard, RetroButton, RetroProgressBar, RetroFont)

### Out of Scope

- Custom resolution input — always 1080p for v1.2
- Multiple resolution presets (720p, 480p) — future milestone
- Batch downscaling — one file at a time
- Video trimming or editing
- Re-encoding audio — copy only
- iOS version, cloud storage

## Context

- GoPro 4K footage is typically H.265/HEVC; output as H.264 for max compatibility
- ffmpeg already a dependency — reuse for video downscaling
- Encoding 4K → 1080p is CPU-intensive; progress tracking via ffmpeg -progress pipe:1 (proven in audio extraction)
- Each tool is an independent TCA module — VideoDownscaler follows AudioExtractor pattern
- Home screen ToolDescriptor array — adding third tool is one array entry
- 8-bit design system tokens already established (DesignTokens.swift, RetroProgressBar, RetroButton, RetroCard)

## Constraints

- **Platform**: macOS desktop app, Swift/SwiftUI
- **Performance**: Must handle 12GB+ files; ffmpeg runs as subprocess
- **Architecture**: Independent TCA module, no coupling with stitch or audio tools
- **Audio**: -c:a copy (zero quality loss, non-negotiable)
- **Video**: H.264 output for compatibility
- **Testing**: Test-first — engine tests before UI wiring
- **Design**: Must use existing 8-bit design system tokens

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| ffmpeg concat with -c copy for stitching | Fast, no re-encoding | ✓ Good |
| Manifest JSON for reversion | Tiny file, enables undo | ✓ Good |
| TCA for state management | Testable, predictable, scales | ✓ Good |
| xcodegen + project.yml | Regenerable, diff-friendly | ✓ Good |
| Extensible ToolDescriptor home screen | Adding tool = one array entry | ✓ Good |
| Independent tool modules | No coupling between tools | ✓ Good |
| ffmpeg for all media ops | Single dependency, all codecs | ✓ Good |
| 8-bit design system | Cohesive retro aesthetic | ✓ Good |
| -c:a copy for downscale | Zero audio quality loss | — Pending |
| H.264 output codec | Maximum playback compatibility | — Pending |
| Auto-name with edit | source_1080p.mp4 default, user can change | — Pending |

---
*Last updated: 2026-03-18 after v1.2 milestone start*
