# Technology Stack: Audio Extraction + Multi-Tool Restructure

**Project:** GoPro Toolkit v1.1
**Researched:** 2026-03-18
**Scope:** Audio extraction from MP4 → MP3 (320kbps) and app restructure as multi-tool launcher
**Confidence:** HIGH (leverages existing validated patterns + verified ffmpeg specifications)

---

## Executive Summary

The audio extraction feature requires **zero new SPM dependencies**. The existing stack (ffmpeg, TCA, AVFoundation) already provides everything needed. The primary technical decision is the specific ffmpeg command-line flags for 320kbps MP3 extraction, which has been verified against FFmpeg documentation. The UI restructure uses existing TCA patterns from v1.0 stitch flow — no new architecture concepts required.

---

## Recommended Stack

### Core Platform (No Changes)

| Technology | Version | Purpose | Status |
|------------|---------|---------|--------|
| Swift | 5.9 | Language | Current |
| macOS | 13.0+ | Deployment target | Current |
| SwiftUI | 3.0+ | View framework | Current |
| Composable Architecture (TCA) | 1.15.0+ | State management | Current |

**Why:** All proven in v1.0. Audio extraction follows identical patterns to stitching.

### Audio Extraction Engine

| Component | Technology | Implementation | Why |
|-----------|-----------|-----------------|-----|
| ffmpeg invocation | Process (Foundation) | Subprocess via Swift's Foundation `Process` API | Same pattern as v1.0 ChunkStitcher; proven, no additional wrapper needed |
| Audio codec | libmp3lame | MP3 encoding in ffmpeg | Industry standard for MP3, ships with ffmpeg, highest quality option |
| Bitrate mode | CBR (Constant Bitrate) | `-b:a 320k` flag | Guarantees exactly 320kbps; predictable file sizes; 320k is max valid MP3 bitrate and highest quality |
| Metadata extraction | AVFoundation + AVMetadataReader | Async API (macOS 13+) | Already in codebase; extracts duration for display before encoding |

**Why NOT VBR:** While Variable Bitrate would be more efficient, CBR is simpler to document ("extract at 320kbps"), provides consistent output, and fits the straightforward use case (not a batch processor). v1.1 is single-file extraction.

### Build & Project Structure (No Changes)

| Technology | Version | Purpose | Status |
|------------|---------|---------|--------|
| xcodegen | Latest | Xcode project generation from project.yml | Current |
| project.yml | Existing | Single source of truth for project config | Current |
| GoProStitcherKit | 1.0 (SPM) | Core logic library | Current, will extend |

---

## ffmpeg Audio Extraction Specification

### Command-Line Flags (Verified)

```bash
ffmpeg -i {input.mp4} \
  -vn \                          # -vn: no video stream
  -acodec libmp3lame \           # libmp3lame: MP3 encoder
  -b:a 320k \                    # -b:a: audio bitrate (CBR mode)
  -q:a 0 \                       # optional: quality hint (0 = highest; helps LAME maintain target bitrate)
  {output.mp3}
```

**Key flags explained:**
- **-vn**: Excludes video stream entirely (more efficient than copy)
- **-acodec libmp3lame**: Uses LAME MP3 encoder (only option for MP3 in ffmpeg)
- **-b:a 320k**: Constant bitrate mode, 320 kilobits/sec (maximum valid MP3 bitrate)
- **-q:a 0**: Quality level 0 (highest quality); helps LAME achieve the target bitrate. Default is 4. Range is 0-9 (0=best, 9=worst).

**Alternative (simpler, no quality hint):**
```bash
ffmpeg -i {input.mp4} -vn -acodec libmp3lame -b:a 320k {output.mp3}
```

This is sufficient; the quality hint is optional tuning.

**Why -vn instead of -acodec copy:** While `-acodec copy` avoids re-encoding (faster), it preserves the source audio codec unchanged. For MP3 extraction, we must re-encode. This is intentional: we want consistent 320k MP3, not variable source bitrate. The re-encode takes 30-60 seconds for a typical 30-min video on modern macOS.

**Sources:**
- [Encode/MP3 – FFmpeg wiki](https://trac.ffmpeg.org/wiki/Encode/MP3) — Best practices and CBR vs. VBR comparison
- [FFmpeg Codecs Documentation](https://ffmpeg.org/ffmpeg-codecs.html) — libmp3lame options (q, b:a, compression_level)
- [How to extract audio from video with FFmpeg — Shotstack](https://shotstack.io/learn/convert-video-mp3-ffmpeg/) — Command examples

---

## Architecture: New AudioExtractor Module

### Location in Kit
Add to `GoProStitcherKit/Sources/GoProStitcherKit/`:

```
AudioExtractor.swift       # Public enum with extract() method (mirrors ChunkStitcher.swift pattern)
AudioExtractorError.swift  # Public error type (mirrors ChunkStitcherError.swift pattern)
```

### Code Pattern (Mirrors ChunkStitcher)

```swift
public enum AudioExtractorError: Error, LocalizedError, Equatable {
    case fileNotFound(URL)
    case ffmpegFailed(String)
    case invalidOutputPath(URL)

    public var errorDescription: String? { ... }
}

public enum AudioExtractor {
    /// Extracts audio from an MP4 file and saves as 320kbps MP3.
    ///
    /// - Parameters:
    ///   - source: URL of input MP4 file
    ///   - destination: URL where output .mp3 will be saved
    ///   - progress: Optional callback fired periodically during encoding
    /// - Throws: `AudioExtractorError` on validation or ffmpeg failure
    public static func extract(source: URL, destination: URL, progress: ((Double) -> Void)? = nil) throws {
        // Validate files
        // Locate ffmpeg (same search paths as ChunkStitcher)
        // Run Process with flagged args
        // Handle progress via stderr parsing (ffmpeg writes progress to stderr)
        // Clean up on failure
    }
}
```

**Why this pattern:**
- Matches existing `ChunkStitcher` public API (Swift enum with static method)
- Error type mirrors `ChunkStitcherError`
- Progress callback follows same pattern as stitch
- All validation and file I/O done synchronously; Process.run() is blocking but Foundation API (no async overhead)

### Progress Tracking Approach

ffmpeg writes real-time statistics to stderr (e.g., `frame=1234 fps=45 time=00:45:30.00 ...`). To track progress:

1. Capture `process.standardError` using `Pipe()`
2. Parse stderr periodically for `time=HH:MM:SS.ms` token
3. Calculate progress as `currentTime / totalDuration` (pre-loaded via AVMetadataReader)
4. Call progress callback with value 0.0...1.0

**Alternative (simpler):** Fire progress callback every N frames rather than smoothly. This avoids stderr parsing complexity.

**Recommendation:** Start simple — fire "started", "complete" events without smooth progress. Add smooth progress in post-MVP if UX testing shows need. ffmpeg extraction on modern hardware takes 30-60 seconds for a 30-min video; users can see something is happening without frame-level updates.

---

## UI Restructure: Home Screen as Tool Launcher

### TCA Feature Hierarchy (Post-Restructure)

```
AppFeature (root reducer)
├── HomeScreenFeature (NEW)
│   ├── StitchToolFeature (promoted from top-level)
│   └── AudioToolFeature (NEW)
└── Active tool state (one of: StitchFlow, AudioFlow, or nil)
```

### Implementation Pattern

The home screen is a new top-level feature (similar to FolderPickerFeature, but shows two buttons instead of picking a folder):

```swift
@Reducer
struct HomeScreenFeature {
    @ObservableState
    struct State: Equatable {
        var selectedTool: Tool? = nil
    }

    enum Tool {
        case stitcher
        case audioExtractor
    }

    enum Action {
        case toolSelected(Tool)
        case stitchButtonTapped
        case audioButtonTapped
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .stitchButtonTapped:
                state.selectedTool = .stitcher
                return .none
            case .audioButtonTapped:
                state.selectedTool = .audioExtractor
                return .none
            case .toolSelected(let tool):
                state.selectedTool = tool
                return .none
            }
        }
    }
}
```

**No new patterns:** This follows standard TCA composition (Scope for each tool). Existing FolderPickerFeature, ChunkReviewFeature, StitchProgressFeature remain unchanged; they're scoped into their respective tool reducers.

### No Architecture Changes Needed

- Each tool is an independent **feature module** (FolderPickerFeature → ChunkReviewFeature → StitchProgressFeature)
- Audio tool follows **identical three-screen pattern**: FilePicker → Metadata/Preview → ExtractionProgress
- **No shared state** between tools (key principle from PROJECT.md: "each tool is independent")
- TCA's `Scope` and `ifLet` operators handle conditional navigation (existing v1.0 pattern)

---

## Dependencies: No Additions Required

### Current Stack (Sufficient)

| Dependency | Used For | Audio Extraction Uses |
|------------|----------|----------------------|
| Foundation | Process, FileManager, URL, AVFoundation | Process for ffmpeg, FileManager for file I/O, AVFoundation for metadata |
| AppKit | NSOpenPanel, NSImage | File picker for MP4 source |
| AVFoundation | Metadata extraction (duration, resolution, thumbnails) | Duration pre-load before extraction (UX) |
| ComposableArchitecture | State management, effects | TCA reducer for extraction flow |
| GoProStitcherKit | Core business logic | Will extend with AudioExtractor module |

**Why no new SPM packages:**
- ffmpeg is system-level tool (installed via `brew install ffmpeg`), not an SPM dependency
- No Swift wrapper for ffmpeg needed; Foundation `Process` API is sufficient and already proven
- AVFoundation covers all metadata needs
- TCA already handles state and async effects

**Alternative considered:** SwiftFFmpeg (https://github.com/sunlubo/SwiftFFmpeg) — Swift wrapper around FFmpeg's C API. Rejected because:
- Adds complexity (C interop, binding maintenance)
- Foundation Process approach is simpler, more maintainable
- v1.0 ChunkStitcher already uses Process approach successfully
- SwiftFFmpeg API still undergoing changes (not stable)

---

## Installation & Configuration

### Dependencies (No Changes to Package.swift)

GoProStitcherKit Package.swift remains:
```swift
let package = Package(
    name: "GoProStitcherKit",
    platforms: [.macOS(.v13)],
    products: [.library(name: "GoProStitcherKit", targets: ["GoProStitcherKit"])],
    targets: [
        .target(name: "GoProStitcherKit"),
        .testTarget(name: "GoProStitcherKitTests", dependencies: ["GoProStitcherKit"], resources: [...])
    ]
)
```

No SPM dependencies added. Audio extraction is pure Swift/Foundation.

### System-Level Setup (User Machine)

ffmpeg must be installed:
```bash
brew install ffmpeg
```

This is the same requirement as v1.0. Recommend checking ffmpeg availability at app launch and showing helpful error if missing (follow v1.0 ChunkStitcher error message pattern).

### Xcode Project (project.yml)

No changes to project.yml needed. Existing structure supports the new AudioExtractor module automatically via target dependencies.

---

## Key Technical Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Use Foundation Process for ffmpeg subprocess | Proven in v1.0, no external dependencies, simple error handling | ✓ Approved |
| CBR 320kbps MP3 encoding | Guarantees output quality, predictable, matches DJ use case (not batch processor) | ✓ Approved |
| Simple progress (events only, not smooth) | Reduces ffmpeg stderr parsing complexity, sufficient for 30-60 second operation | ✓ Approved |
| TCA three-screen pattern for audio flow | Mirrors stitch flow, reuses navigation patterns, testable | ✓ Approved |
| Independent tool modules (no shared state) | Scales to future tools, keeps audio extraction focused, prevents coupling | ✓ Approved |
| No new SPM dependencies | Minimizes build complexity, reduces maintenance burden | ✓ Approved |

---

## Risks & Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|-----------|
| ffmpeg not installed on user machine | Medium | Detect at app launch (same as v1.0), show "Install ffmpeg with: brew install ffmpeg" |
| ffmpeg subprocess hangs on corrupted MP4 | Low | Set process timeout (10 minutes); cancel and fail gracefully |
| MP3 output file path collision | Low | Validate output path doesn't exist before starting; fail with clear error |
| Slow extraction on large files (12GB+) | Low | Extraction is O(file size); 30-60 seconds is acceptable for one-time operation. Mention in docs. |
| AVMetadataReader fails to load duration | Low | Gracefully handle nil duration; show "extracting" without time-based progress bar |

---

## File Locations & Naming

### New files in GoProStitcherKit
```
GoProStitcherKit/Sources/GoProStitcherKit/
├── AudioExtractor.swift          (public API)
├── AudioExtractorError.swift     (public error type)
```

### New test resources
```
GoProStitcherKit/Tests/GoProStitcherKitTests/Resources/
├── sample-audio.mp4              (test fixture: small MP4 with audio)
```

### New feature in main app
```
GoProStitcher/Features/
├── AudioExtraction/              (NEW)
│   ├── AudioExtractionFeature.swift
│   ├── AudioExtractionView.swift
│   ├── FilePicker/               (select source MP4)
│   ├── ExtractionProgress/       (show progress + result)
│   └── MetadataPreview/          (show duration, file size before extract)
├── HomeScreen/                   (NEW)
│   ├── HomeScreenFeature.swift
│   └── HomeScreenView.swift
```

---

## Summary for Roadmap

**Phase Structure Recommendation:**

1. **AudioExtractor Core (Kit):** Implement `AudioExtractor.swift` + error handling + unit tests. This is the "synchronous API boundary." ~200 lines of code, uses existing ffmpeg search logic from ChunkStitcher.

2. **Audio Flow Features:** Three TCA reducers for file picker, metadata preview, and extraction progress. Reuse existing patterns from stitch flow. ~400 lines of UI logic.

3. **Home Screen Restructure:** Create HomeScreenFeature, wrap both stitch and audio flows as independent tools. Update AppFeature to route through home screen. ~200 lines.

**Why this order:**
- Core API first (testable, no UI dependencies)
- Feature implementation second (uses proven core API)
- Navigation restructure last (integrates both tools)

**No blockers:** All dependencies exist, ffmpeg approach verified, no unknown technical gaps.

---

## Sources

### FFmpeg Documentation
- [Encode/MP3 – FFmpeg Wiki](https://trac.ffmpeg.org/wiki/Encode/MP3) — CBR vs. VBR, libmp3lame options
- [FFmpeg Codecs Documentation](https://ffmpeg.org/ffmpeg-codecs.html) — libmp3lame reference (quality, bitrate, compression_level)

### FFmpeg Audio Extraction Examples
- [How to extract audio from video using FFmpeg - Shotstack](https://shotstack.io/learn/convert-video-mp3-ffmpeg/) — Command examples
- [Extract Audio from Video using FFmpeg - OTTVerse](https://ottverse.com/extract-audio-from-video-using-ffmpeg/) — Practical guide

### Swift & macOS Integration
- [Extract audio on iOS & macOS with FFmpeg - Transloadit](https://transloadit.com/devtips/extract-audio-on-ios-macos-with-ffmpeg/) — Process-based approach for macOS
- [Using Swift Forums: running ffmpeg via Process](https://forums.swift.org/t/having-some-issues-running-ffmpeg-via-process/20575) — Subprocess management patterns

---

**Last updated:** 2026-03-18
**Next phase:** Roadmap creation will use this stack specification to structure the v1.1 milestone phases.
