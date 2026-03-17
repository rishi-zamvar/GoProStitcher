---
phase: 03-review-preview-reorder
plan: "03"
subsystem: ui
tags: [swiftui, avkit, avfoundation, tca, composable-architecture, perception, macos]

# Dependency graph
requires:
  - phase: 03-02
    provides: ChunkReviewFeature reducer (reorder, preview, metadata loading)
  - phase: 03-01
    provides: AVMetadataReader for async duration/resolution/thumbnail extraction
  - phase: 02-03
    provides: FolderPickerFeature and FolderPickerView pattern to follow
provides:
  - ChunkReviewView: scrollable list with thumbnails, metadata, drag-to-reorder
  - ChunkPreviewModal: AVPlayerView sheet playing first 3 seconds of clip
  - AppFeature root reducer composing FolderPickerFeature + ChunkReviewFeature
  - Navigation: FolderPickerView -> ChunkReviewView on successful scan
affects: [04-stitching-progress, future-ui-phases]

# Tech tracking
tech-stack:
  added: [Perception (backport @Bindable for macOS 13)]
  patterns:
    - "@Perception.Bindable for StoreOf<> on macOS 13 deployment target"
    - "Root AppFeature reducer composing child features and managing navigation via optional state"
    - "URL+Identifiable via @retroactive conformance for sheet(item:) pattern"
    - "NSViewRepresentable wrapping AVPlayerView for SwiftUI integration"

key-files:
  created:
    - GoProStitcher/Features/ChunkReview/ChunkReviewView.swift
    - GoProStitcher/Features/ChunkReview/ChunkPreviewModal.swift
    - GoProStitcher/AppFeature.swift
  modified:
    - GoProStitcher/ContentView.swift
    - GoProStitcher/GoProStitcherApp.swift
    - GoProStitcher.xcodeproj/project.pbxproj

key-decisions:
  - "@Perception.Bindable instead of @SwiftUI.Bindable — deployment target is macOS 13, SwiftUI.Bindable requires macOS 14"
  - "sheet(isPresented:) with manual Binding<Bool> instead of sheet(item:) with store binding — avoids .sending() complexity"
  - "AppFeature as root reducer with optional chunkReview state — nil means picker screen, non-nil means review screen"
  - "store.scope(state: \\.chunkReview!, action: \\.chunkReview) — force-unwrap safe because only reached when non-nil"

patterns-established:
  - "Root AppFeature pattern: compose child features, route navigation via optional child state"
  - "NSViewRepresentable for AppKit video views: AVPlayerItem.forwardPlaybackEndTime for clip trimming"

# Metrics
duration: 4min
completed: 2026-03-18
---

# Phase 3 Plan 03: ChunkReviewView + Navigation Summary

**SwiftUI review screen with drag-to-reorder list, AVPlayer 3-second preview modal, and AppFeature root reducer navigating FolderPicker -> ChunkReview on successful scan**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-17T22:26:11Z
- **Completed:** 2026-03-17T22:29:56Z
- **Tasks:** 3 (2 auto + 1 human-verify checkpoint — approved)
- **Files modified:** 6

## Accomplishments

- ChunkReviewView renders scrollable list: gray placeholder thumbnails, monospaced filenames, duration/size/resolution metadata line per row
- Drag-to-reorder wired via `.onMove` to `chunksReordered` TCA action; immediate reorder without lag
- ChunkPreviewModal wraps AVPlayerView via NSViewRepresentable, sets `forwardPlaybackEndTime` to 3s, plays on appear; Close button + Escape dismiss cleanly
- AppFeature root reducer composes FolderPickerFeature + ChunkReviewFeature; `.ifLet` wires optional chunkReview; transitions on `scanCompleted(.success(chunks))`
- ContentView now driven by AppFeature store; GoProStitcherApp initializes single store at top level

## Task Commits

Each task was committed atomically:

1. **Task 1: ChunkReviewView + ChunkPreviewModal** - `e2c8cb1` (feat)
2. **Task 2: Wire ContentView — AppFeature + navigation** - `678d6d4` (feat)

## Files Created/Modified

- `GoProStitcher/Features/ChunkReview/ChunkReviewView.swift` — SwiftUI list view with ChunkRowView, @Perception.Bindable, sheet presentation
- `GoProStitcher/Features/ChunkReview/ChunkPreviewModal.swift` — AVPlayerViewRepresentable + modal layout with Close button
- `GoProStitcher/AppFeature.swift` — Root reducer composing FolderPickerFeature and ChunkReviewFeature, handles navigation transition
- `GoProStitcher/ContentView.swift` — Updated to accept AppFeature store, routes to FolderPickerView or ChunkReviewView
- `GoProStitcher/GoProStitcherApp.swift` — Initializes AppFeature store, passes to ContentView
- `GoProStitcher.xcodeproj/project.pbxproj` — Regenerated via xcodegen to include new files

## Decisions Made

- **@Perception.Bindable**: SwiftUI's `@Bindable` requires macOS 14+; deployment target is 13.0. TCA bundles swift-perception which backports `Bindable` as `Perception.Bindable` for macOS 10.15–13.
- **sheet(isPresented:) over sheet(item:)**: Avoids needing `.sending()` on a `Binding<URL?>` which would conflict with the TCA action semantics. Manual `Binding<Bool>` reads `selectedPreviewURL != nil` and fires `previewDismissed` on dismiss.
- **AppFeature optional state navigation**: `chunkReview: ChunkReviewFeature.State? = nil` means picker is visible; setting it to non-nil switches the view. Clean, no router library needed at this scale.
- **force-unwrap in scope**: `store.scope(state: \\.chunkReview!, action: \\.chunkReview)` is safe because ContentView only reaches that branch when `chunkReview != nil`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] @Bindable ambiguity and macOS 14 availability**

- **Found during:** Task 1 (ChunkReviewView)
- **Issue:** Plan specified `@Bindable var store: StoreOf<ChunkReviewFeature>` but this resolved to `SwiftUI.Bindable` which requires macOS 14, not macOS 13 (deployment target). Build error: "'Bindable' is only available in macOS 14.0 or newer"
- **Fix:** Added `import Perception` and qualified as `@Perception.Bindable` — the backport included via swift-perception (TCA dependency)
- **Files modified:** ChunkReviewView.swift
- **Verification:** BUILD SUCCEEDED with only warnings
- **Committed in:** e2c8cb1

**2. [Rule 1 - Bug] sheet(item:) with .sending() not viable**

- **Found during:** Task 1 (ChunkReviewView sheet presentation)
- **Issue:** Plan's `.sheet(item: $store.selectedPreviewURL.sending(\.chunkTapped))` would invoke `chunkTapped` on dismiss, not `previewDismissed`. Wrong action fired.
- **Fix:** Replaced with `sheet(isPresented:)` using a manual `Binding<Bool>` that reads the optional and fires `previewDismissed` on false.
- **Files modified:** ChunkReviewView.swift
- **Verification:** Build succeeds; dismiss logic sends correct action
- **Committed in:** e2c8cb1

---

**Total deviations:** 2 auto-fixed (both Rule 1 - Bug: compiler errors / incorrect action routing)
**Impact on plan:** Both fixes required for correctness and macOS 13 compatibility. No scope creep.

## Issues Encountered

The plan's `@Bindable` annotation was written for macOS 14+. Since the deployment target is macOS 13, the Perception backport must be used explicitly. The `swift-perception` package is already a transitive dependency of TCA 1.25.x, so no new packages were needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All four ORDER requirements (ORDER-01 through ORDER-04) confirmed visually by human verification
- Phase 3 is fully complete; Phase 4 (stitching + progress screen) can begin
- No blockers identified

---
*Phase: 03-review-preview-reorder*
*Completed: 2026-03-18*
