# Phase 1: Testing Infrastructure & Project Foundation - Context

**Gathered:** 2026-03-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Xcode project scaffolded with test targets, mock MP4 generators, and test utilities ready to support feature development. This phase creates the foundation — no feature code, no UI beyond compilation. All feature phases (2-4) build on this infrastructure.

</domain>

<decisions>
## Implementation Decisions

### Mock MP4 Strategy
- Real GoPro sample clips used as test fixtures — not programmatically generated
- Two tiers: tiny clips (~1-5 MB each, trimmed from real GoPro chunks) checked into git for CI; full-size 4GB files in a gitignored `test-data/` folder in the project root for local integration testing
- All test fixtures use standard GoPro output (same resolution/fps) — no mixed settings
- Full-size test path: `./test-data/` (gitignored), tiny fixtures: bundled in test target resources

### Test Scope & Coverage
- 95%+ line coverage target across all components
- All failure scenarios must be tested: disk exhaustion mid-stitch, corrupted MP4 in sequence, permission denied on read/write, interrupted operation (quit/sleep)
- On stitch failure: revert to original file 1 (backup before stitching starts, restore on failure)
- Full test suite (unit + integration + UI) runs on every build — maximum confidence, no on-demand-only tests

### Project Structure
- Separate Swift Package: `GoProStitcherKit` contains all core logic (parsing, stitching, archiving, file validation)
- App target is UI-only (SwiftUI views + TCA features), depends on GoProStitcherKit
- Architecture: TCA (The Composable Architecture) for testability
- Minimum target: macOS 13 (Ventura)
- Three test targets: unit tests (GoProStitcherKit logic), integration tests (full pipeline), UI tests (navigation/interactions)

### GoPro Naming Patterns
- Support HERO 9-13 (newer models) only: GX prefix (.MP4 HEVC) and GH prefix (.MP4 H.264)
- Do NOT handle older GOPR/GP prefixes (HERO 5-8) — not needed
- Files always have original GoPro names (straight off SD card) — no renamed file handling
- Only show files matching GX/GH naming pattern — ignore any MP4 that doesn't match
- Naming format: `GX{chapter}{file_number}.MP4` or `GH{chapter}{file_number}.MP4` where chapter is 2 digits and file_number is 4 digits

### Claude's Discretion
- Test helper API design (temp directory management, cleanup, assertions)
- Exact TCA dependency injection patterns for file system access
- CI script format (xcodebuild commands, test output parsing)
- How to structure the backup/restore mechanism for stitch failure recovery

</decisions>

<specifics>
## Specific Ideas

- Test fixtures should be real GoPro clips so we test against actual MP4 container format, not synthetic approximations
- The backup-before-stitch approach means we need reliable disk space checking before starting (space for backup of file 1 + the append operations)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-testing-infrastructure*
*Context gathered: 2026-03-17*
