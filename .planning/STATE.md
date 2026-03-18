# STATE: GoPro Toolkit

**Last Updated:** 2026-03-18 (v1.1 milestone started — Extract Audio + App Restructure)

---

## Project Reference

**Core Value:** A DJ/creator has a single app for all their GoPro post-processing needs — stitch chunks, extract audio, and future tools — without leaving the app or learning complex software.

**Key Constraints:**
- macOS desktop app only (Swift/SwiftUI)
- Each tool is an independent TCA module — no shared pipeline
- Test-first approach: engine tests before UI wiring
- ffmpeg required dependency (already present)
- Extensible home screen for adding tools later

**Milestone:** v1.1 (Extract Audio + App Restructure)

---

## Current Position

**Phase:** Not started (defining requirements)
**Status:** Defining requirements for v1.1
**Last activity:** 2026-03-18 — Milestone v1.1 started

**Progress:** ░░░░░░░░░░ 0%

**Current Focus:**
v1.0 complete and shipped. Starting v1.1: rename app to GoPro Toolkit, restructure as tool launcher, add MP3 extraction.

---

## Performance Metrics

**Execution Mode:** yolo (rapid iteration)
**Depth:** quick (3-5 phases, 1-3 plans each)
**Parallelization:** Enabled
**Plan Check:** Disabled
**Verifier:** Enabled
**Commit Docs:** Enabled

**KPIs (v1.1 success):**
- App renamed to GoPro Toolkit throughout
- Home screen with extensible tool buttons
- Existing stitch flow accessible from home screen
- Audio extraction produces valid 320kbps MP3 from any MP4
- Auto-reveal in Finder after extraction
- All new features test-covered

---

## Accumulated Context

### Decisions Made

| Decision | Rationale | Status |
|----------|-----------|--------|
| Test-first approach | Comprehensive testing infrastructure built first | Locked for all phases |
| xcodegen + project.yml | Regenerable, diff-friendly Xcode project | Locked |
| swift-tools-version 5.9 | macOS 13 deployment target | Locked |
| TCA Feature pattern | One reducer + one view per feature, under Features/ | Locked |
| caseless enum for engines | Pure static namespace pattern for utility types | Locked |
| @Perception.Bindable | macOS 13 backport for SwiftUI.Bindable | Locked |
| NSOpenPanel via MainActor.run | AppKit + TCA concurrency rules | Locked |
| ffmpeg for video operations | Already a dependency, handles all codecs | Locked |
| Two big buttons home screen | Simple, extensible tool launcher | New for v1.1 |
| Independent tool modules | No coupling between stitch and extract | New for v1.1 |

### Known Constraints

- **Performance:** Files are 12GB+; must avoid memory buffering entire file
- **Platform:** macOS 13+ deployment target
- **Testing:** Mock MP4 fixtures must have valid headers; temp directory cleanup must be reliable
- **ffmpeg:** Must be installed on user's system (brew install ffmpeg)

### Blockers

None identified at this stage.

---

## Session Continuity

**Last Session:** 2026-03-18 - Started v1.1 milestone
**Stopped at:** Defining requirements
**Resume file:** None

**Next Session:** Define requirements → create roadmap → plan phase 5

---

*State initialized: 2026-03-17 by roadmapper*
*State reset: 2026-03-18 for v1.1 milestone*
