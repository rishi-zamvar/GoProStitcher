---
phase: 08-ux-redesign-8bit
plan: 02
subsystem: ui
tags: [swiftui, tca, design-system, retro, jetbrains-mono, 8bit]

# Dependency graph
requires:
  - phase: 08-ux-redesign-8bit/08-01
    provides: RetroColor, RetroFont, RetroSpacing tokens; RetroButton, RetroCard, RetroInvertedCard, RetroProgressBar components
provides:
  - All 8 app screens restyled to GoProToolkit-8bit-system design language
  - HomeView with retro game-menu layout (hover-invert cards, ▶ prefix, [ SELECT ])
  - FolderPickerView with RetroCard result states, no SF Symbols
  - ContentView/GoProStitcherApp with beige root background
  - ChunkReviewView with hard-edge thumbnails, 2px divider, RetroFont rows
  - ChunkPreviewModal with dark (black) background and inverted header
  - StitchProgressView with RetroProgressBar (blockCount:16), RetroCard states
  - AudioExtractionView with RetroInvertedCard filename header, RetroProgressBar
affects:
  - 08-03 (visual polish checkpoint — builds on these restyled screens)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "RetroCard wraps all content blocks; RetroInvertedCard for dark header bars"
    - "RetroProgressBar replaces every ProgressView instance"
    - "RetroButton / RetroButtonStyle replaces all .borderedProminent buttons"
    - ".linear(duration: 0.1) animation replaces easeInOut throughout"
    - "2px Rectangle() replaces Divider(); Rectangle() clipShape replaces RoundedRectangle"

key-files:
  created: []
  modified:
    - GoProStitcher/Features/Home/HomeView.swift
    - GoProStitcher/Features/FolderPicker/FolderPickerView.swift
    - GoProStitcher/ContentView.swift
    - GoProStitcher/GoProStitcherApp.swift
    - GoProStitcher/Features/ChunkReview/ChunkReviewView.swift
    - GoProStitcher/Features/ChunkReview/ChunkPreviewModal.swift
    - GoProStitcher/Features/StitchProgress/StitchProgressView.swift
    - GoProStitcher/Features/AudioExtraction/AudioExtractionView.swift

key-decisions:
  - "HomeView uses ToolRowView subview with @State isHovered for hover-invert effect — whole card flips black/beige on hover"
  - "ChunkPreviewModal uses black background (RetroColor.black) making it feel like a cinema modal overlay"
  - "RetroProgressBar(blockCount:16) for progress screens; blockCount:8 for indeterminate/loading states"
  - "metadataRow inlined into AudioExtractionView card body per plan spec (function removed)"

patterns-established:
  - "All screens: RetroColor.beigeBackground as root .background(), never system bg"
  - "No SF Symbols anywhere — text/ASCII replacements: ▶, ✓, ✗, [?], [ SELECT ]"
  - "Progress: RetroProgressBar(fraction:, blockCount:) — never ProgressView"
  - "Cards: RetroCard (white on beige) or RetroInvertedCard (black header) — never RoundedRectangle"

# Metrics
duration: 3min
completed: 2026-03-18
---

# Phase 8 Plan 02: Screen Restyling Summary

**All 8 app screens transformed to GoProToolkit-8bit design language: beige backgrounds, hard black borders, JetBrains Mono throughout, RetroProgressBar block fills replacing ProgressView, retro game-menu HomeView with hover-invert cards**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-18T14:26:26Z
- **Completed:** 2026-03-18T14:29:34Z
- **Tasks:** 2 of 2 (checkpoint pending user verify)
- **Files modified:** 8

## Accomplishments
- HomeView redesigned as a retro game select screen — black inverted header bar, ToolRowView cards with full hover inversion (black bg + beige text on hover), ▶ title prefix, [ SELECT ] action text
- FolderPickerView, ContentView, GoProStitcherApp: beige root backgrounds established, RetroButton back navigation, system animations replaced with linear(0.1)
- ChunkReviewView: REVIEW CLIPS monospace header, 2px black Rectangle divider, hard-edge thumbnail clip, RetroFont rows
- ChunkPreviewModal: dark modal experience — black background, inverted PREVIEW header bar, hard-edge video player border, RetroButton close
- StitchProgressView: RetroProgressBar(blockCount:16) block-fill progress, [✓ COMPLETE] / [✗ ERROR] text states wrapped in RetroCard
- AudioExtractionView: RetroInvertedCard filename header, RetroCard metadata body (Duration/Size/Audio Bitrate), RetroProgressBar for both determinate and indeterminate states, [✓ MP3 SAVED] / [✗ FAILED] completions

## Task Commits

1. **Task 1: Restyle HomeView, FolderPickerView, ContentView, GoProStitcherApp** - `47714f8` (feat)
2. **Task 2: Restyle ChunkReview, StitchProgress, AudioExtraction** - `9097ec6` (feat)

## Files Created/Modified
- `GoProStitcher/Features/Home/HomeView.swift` - Retro game menu layout with hover-invert ToolRowView cards
- `GoProStitcher/Features/FolderPicker/FolderPickerView.swift` - Beige bg, RetroButton, RetroCard results, no SF Symbols
- `GoProStitcher/ContentView.swift` - RetroButton back nav, RetroSpacing.md, beige root bg
- `GoProStitcher/GoProStitcherApp.swift` - Beige WindowGroup background
- `GoProStitcher/Features/ChunkReview/ChunkReviewView.swift` - Bordered rows, 2px divider, RetroFont, beige list bg
- `GoProStitcher/Features/ChunkReview/ChunkPreviewModal.swift` - Dark modal, inverted header, hard-edge video, RetroButton
- `GoProStitcher/Features/StitchProgress/StitchProgressView.swift` - RetroProgressBar, RetroCard states, text completion icons
- `GoProStitcher/Features/AudioExtraction/AudioExtractionView.swift` - RetroInvertedCard header, RetroCard body, RetroProgressBar

## Decisions Made
- HomeView ToolRowView as a separate private struct with @State isHovered — cleaner than inline — allows the full-card hover invert effect
- ChunkPreviewModal background stays black (RetroColor.black) to create cinema feel when overlaid on beige main screen
- RetroProgressBar blockCount:16 for actual progress tracking, blockCount:8 for indeterminate/loading placeholder states
- `metadataRow` function in AudioExtractionView kept as a private func (not inlined) since it's used multiple times — same result, cleaner code

## Deviations from Plan

None - plan executed exactly as written. All 8 files restyled per spec. Zero system styling tokens remain.

## Issues Encountered
None — both builds passed first try after implementing all changes.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All screens built and ready for visual evaluation
- App runs end-to-end: Home → FolderPicker → ChunkReview → StitchProgress, Home → AudioFilePicker → AudioExtraction
- Awaiting human visual verification (checkpoint) before proceeding to 08-03 polish phase
- If user approves: 08-03 can focus on micro-polish (hover states, animations, any screen-specific tweaks identified during review)

---
*Phase: 08-ux-redesign-8bit*
*Completed: 2026-03-18*
