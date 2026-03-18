# Architecture Patterns: Audio Extraction + Multi-Tool Restructure

**Project:** GoPro Toolkit v1.1
**Researched:** 2026-03-18
**Scope:** Audio extraction integration and home screen restructuring
**Confidence:** HIGH (proven TCA patterns from v1.0 + standard subprocess management)

---

## Executive Summary

V1.1 architecture is straightforward. The app transitions from single-flow (folder picker → review → stitch) to multi-tool launcher (home screen routes to independent flows). Each tool (stitch, audio) is a self-contained TCA reducer with no shared state. Audio extraction uses the same Process-based ffmpeg invocation as v1.0 stitching. No new architectural paradigms; this is a straightforward application of established TCA composition patterns.

---

## Recommended Architecture

### High-Level Structure

```
┌─────────────────────────────────────────────────────────┐
│         GoPro Toolkit App (Main Entry Point)            │
├─────────────────────────────────────────────────────────┤
│                 AppFeature (TCA Root)                   │
│                                                         │
│  State:  homeScreen: HomeScreenFeature.State            │
│          stitchFlow: StitchFlowFeature.State? (v1.0)   │
│          audioFlow: AudioFlowFeature.State? (new)      │
│                                                         │
│  Routes to:                                             │
│    1. HomeScreenFeature (shows two buttons)             │
│    2. StitchFlowFeature (unchanged from v1.0)          │
│    3. AudioFlowFeature (new, mirrors stitch)           │
└─────────────────────────────────────────────────────────┘
                    ↓ routes to ↓
        ┌───────────────┼───────────────┐
        ↓               ↓               ↓
  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
  │ HomeScreen   │  │ StitchFlow   │  │ AudioFlow    │
  │ Feature      │  │ (v1.0        │  │ (new)        │
  │ (new)        │  │ unchanged)   │  │              │
  └──────────────┘  └──────────────┘  └──────────────┘
       ↓                  ↓                  ↓
    Shows:          FolderPicker →      FilePicker →
    2 buttons       ChunkReview →       AudioPreview →
    "Stitch"        StitchProgress      ExtractionProgress
    "Extract"
```

---

## Component Boundaries

### AppFeature (Root Reducer) — Updated

**Responsibility:** Top-level navigation between home screen and active tools.

```swift
@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var homeScreen = HomeScreenFeature.State()
        /// Non-nil when user has selected stitch flow
        var stitchFlow: StitchFlowFeature.State? = nil
        /// Non-nil when user has selected audio flow
        var audioFlow: AudioFlowFeature.State? = nil
    }

    enum Action {
        case homeScreen(HomeScreenFeature.Action)
        case stitchFlow(StitchFlowFeature.Action)
        case audioFlow(AudioFlowFeature.Action)
    }

    var body: some ReducerOf<Self> {
        // Home screen always visible/routable
        Scope(state: \.homeScreen, action: \.homeScreen) {
            HomeScreenFeature()
        }

        // Route home screen selections to tool activation
        Reduce { state, action in
            switch action {
            case .homeScreen(.stitchButtonTapped):
                state.stitchFlow = StitchFlowFeature.State()
                return .none

            case .homeScreen(.audioButtonTapped):
                state.audioFlow = AudioFlowFeature.State()
                return .none

            case .homeScreen:
                return .none

            case .stitchFlow(.backPressed):
                state.stitchFlow = nil
                return .none

            case .audioFlow(.backPressed):
                state.audioFlow = nil
                return .none

            case .stitchFlow, .audioFlow:
                return .none
            }
        }

        // Scope both flows independently
        .ifLet(\.stitchFlow, action: \.stitchFlow) {
            StitchFlowFeature()
        }
        .ifLet(\.audioFlow, action: \.audioFlow) {
            AudioFlowFeature()
        }
    }
}
```

**Changes from v1.0:**
- Wraps existing v1.0 logic (folder picker → review → stitch) into StitchFlowFeature
- Adds new audioFlow optional state
- Routes home screen button taps to tool activation
- Listens for back/dismissal actions to clear tool state

---

### HomeScreenFeature (New)

**Responsibility:** Display two tool buttons; notify parent when user selects a tool.

```swift
@Reducer
struct HomeScreenFeature {
    @ObservableState
    struct State: Equatable {
        // No sub-state needed; just a simple button display
    }

    enum Action {
        case stitchButtonTapped
        case audioButtonTapped
    }

    var body: some ReducerOf<Self> {
        EmptyReducer()  // No side effects; just display and delegate
    }
}
```

**Size:** ~20 lines code. Pure presentation.

**View Pattern:**
```swift
struct HomeScreenView: View {
    let store: StoreOf<HomeScreenFeature>

    var body: some View {
        VStack {
            Button("Stitch Video") {
                store.send(.stitchButtonTapped)
            }
            Button("Extract Audio") {
                store.send(.audioButtonTapped)
            }
        }
    }
}
```

---

### StitchFlowFeature (Refactored from v1.0 AppFeature)

**Responsibility:** Manage stitch workflow (folder picker → review → progress).

**No changes to internal structure.** Copy existing AppFeature logic here:

```swift
@Reducer
struct StitchFlowFeature {
    @ObservableState
    struct State: Equatable {
        var folderPicker = FolderPickerFeature.State()
        var chunkReview: ChunkReviewFeature.State? = nil
        var stitchProgress: StitchProgressFeature.State? = nil
    }

    enum Action {
        case folderPicker(FolderPickerFeature.Action)
        case chunkReview(ChunkReviewFeature.Action)
        case stitchProgress(StitchProgressFeature.Action)
        case backPressed  // Return to home screen
    }

    var body: some ReducerOf<Self> {
        // Identical to current AppFeature logic
        Scope(state: \.folderPicker, action: \.folderPicker) {
            FolderPickerFeature()
        }
        Reduce { state, action in
            switch action {
            case let .folderPicker(.scanCompleted(.success(chunks))):
                state.chunkReview = ChunkReviewFeature.State(chunks: chunks)
                return .none

            case .chunkReview(.startStitching):
                guard let review = state.chunkReview else { return .none }
                state.stitchProgress = StitchProgressFeature.State(chunks: review.chunks)
                return .send(.stitchProgress(.startStitch))

            case .chunkReview, .folderPicker:
                return .none

            case .stitchProgress:
                return .none

            case .backPressed:
                return .none  // Handled by parent AppFeature
            }
        }
        .ifLet(\.chunkReview, action: \.chunkReview) {
            ChunkReviewFeature()
        }
        .ifLet(\.stitchProgress, action: \.stitchProgress) {
            StitchProgressFeature()
        }
    }
}
```

**Mirrors v1.0 structure exactly.** Just wrapped at one level higher.

---

### AudioFlowFeature (New)

**Responsibility:** Manage audio extraction workflow (file picker → preview → progress).

```swift
@Reducer
struct AudioFlowFeature {
    @ObservableState
    struct State: Equatable {
        var filePicker = AudioFilePickerFeature.State()
        var preview: AudioPreviewFeature.State? = nil
        var progress: AudioExtractionProgressFeature.State? = nil
    }

    enum Action {
        case filePicker(AudioFilePickerFeature.Action)
        case preview(AudioPreviewFeature.Action)
        case progress(AudioExtractionProgressFeature.Action)
        case backPressed
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.filePicker, action: \.filePicker) {
            AudioFilePickerFeature()
        }

        Reduce { state, action in
            switch action {
            case let .filePicker(.fileSelected(url)):
                // Load duration async and create preview state
                state.preview = AudioPreviewFeature.State(sourceURL: url)
                return .none

            case let .preview(.extractionApproved(url)):
                // User clicked "Extract" — start progress
                state.progress = AudioExtractionProgressFeature.State(sourceURL: url)
                return .send(.progress(.startExtraction))

            case .preview, .filePicker:
                return .none

            case .progress:
                return .none

            case .backPressed:
                return .none  // Handled by parent AppFeature
            }
        }

        .ifLet(\.preview, action: \.preview) {
            AudioPreviewFeature()
        }
        .ifLet(\.progress, action: \.progress) {
            AudioExtractionProgressFeature()
        }
    }
}
```

**Size:** ~80-100 lines. Identical pattern to StitchFlowFeature.

---

## Component Interaction Diagram

```
AppFeature (root)
├── HomeScreenFeature
│   └── user taps button → sends homeScreen(.stitchButtonTapped)
│       → AppFeature receives, sets stitchFlow = StitchFlowFeature.State()
│
├── StitchFlowFeature (optional, when stitch is active)
│   ├── FolderPickerFeature (always visible initially)
│   ├── ChunkReviewFeature (optional, when folder selected)
│   └── StitchProgressFeature (optional, when stitch starts)
│
└── AudioFlowFeature (optional, when audio is active)
    ├── AudioFilePickerFeature (always visible initially)
    ├── AudioPreviewFeature (optional, when file selected)
    └── AudioExtractionProgressFeature (optional, when extract starts)
```

**Key property:** Only ONE tool is active at a time. If user is in StitchFlowFeature and taps back, stitch flow is cleared and home reappears. If user then taps audio, AudioFlowFeature is set.

---

## Data Flow: Core Scenario

### Scenario: User Extracts Audio

```
1. App launches
   → AppFeature initializes
   → homeScreen visible

2. User taps "Extract Audio" button
   → HomeScreenView sends .audioButtonTapped
   → HomeScreenFeature action → AppFeature.homeScreen(.audioButtonTapped)
   → AppFeature receives: state.audioFlow = AudioFlowFeature.State()

3. AudioFlowFeature initializes
   → AudioFilePickerFeature visible (NSOpenPanel ready)
   → AppFeature renders AudioFlowFeature (via .ifLet)

4. User selects video.mp4
   → AudioFilePickerFeature sends .fileSelected(url)
   → AudioFlowFeature receives, computes duration (async), creates preview state
   → state.preview = AudioPreviewFeature.State(sourceURL: url)

5. AudioPreviewFeature visible
   → Shows filename, duration, size
   → User taps [Extract] button
   → AudioPreviewFeature sends .extractionApproved(url)
   → AudioFlowFeature receives, creates progress state
   → state.progress = AudioExtractionProgressFeature.State(sourceURL: url)

6. AudioExtractionProgressFeature visible
   → Shows "Extracting..." status
   → Calls AudioExtractor.extract(source, destination) from kit
   → ffmpeg subprocess runs (30-60 seconds)
   → On success: fires .revealInFinder(mp3URL)
   → Finder auto-selects the MP3

7. User taps [Done] button
   → AudioExtractionProgressFeature sends .backPressed
   → AudioFlowFeature receives: AppFeature.audioFlow(.backPressed)
   → AppFeature receives: state.audioFlow = nil

8. HomeScreenFeature visible again
   → User can tap "Stitch" or "Extract" again
```

**Key pattern:** Each state transition is explicit. No UI magic; all state changes go through reducers.

---

## Kit Architecture: AudioExtractor Module

### Location in GoProStitcherKit

```
GoProStitcherKit/Sources/GoProStitcherKit/
├── ChunkStitcher.swift         (v1.0, unchanged)
├── ChunkStitcherError.swift    (v1.0, unchanged)
├── AudioExtractor.swift        (NEW)
├── AudioExtractorError.swift   (NEW)
└── ... other modules
```

### AudioExtractor Implementation (Process-Based)

```swift
// AudioExtractorError.swift
public enum AudioExtractorError: Error, LocalizedError, Equatable {
    case sourceFileNotFound(URL)
    case ffmpegFailed(String)
    case invalidDestination(URL)
}

// AudioExtractor.swift
public enum AudioExtractor {
    /// Extracts audio from source MP4 to destination MP3 (320kbps CBR).
    /// Uses ffmpeg subprocess, same approach as ChunkStitcher.
    ///
    /// - Parameters:
    ///   - source: Input MP4 URL
    ///   - destination: Output MP3 URL (must not exist)
    ///   - progress: Optional callback for progress events
    /// - Throws: AudioExtractorError
    public static func extract(
        source: URL,
        destination: URL,
        progress: ((ExtractionEvent) -> Void)? = nil
    ) throws {
        // Validate files
        guard FileManager.default.fileExists(atPath: source.path) else {
            throw AudioExtractorError.sourceFileNotFound(source)
        }

        // Find ffmpeg (same search as ChunkStitcher)
        let ffmpegPath = ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"]
            .first { FileManager.default.fileExists(atPath: $0) }
        guard let ffmpeg = ffmpegPath else {
            throw AudioExtractorError.ffmpegFailed("ffmpeg not found. Install: brew install ffmpeg")
        }

        // Run ffmpeg with verified flags
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpeg)
        process.arguments = [
            "-i", source.path,
            "-vn",                         // no video
            "-acodec", "libmp3lame",       // MP3 encoder
            "-b:a", "320k",                // 320kbps CBR
            destination.path
        ]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            // Clean up partial output on failure
            try? FileManager.default.removeItem(at: destination)
            throw AudioExtractorError.ffmpegFailed("exit code \(process.terminationStatus)")
        }

        progress?(.completed(destination))
    }

    public enum ExtractionEvent {
        case started
        case completed(URL)
        case failed(Error)
    }
}
```

**Pattern:** Identical to ChunkStitcher (synchronous, blocking, simple error handling).

---

## Patterns to Follow

### Pattern 1: Independent Tool Modules

**What:** Each tool (stitch, audio) is a self-contained feature hierarchy with no coupling.

**When:** Always use this for new tools.

**Example:**
```swift
// Stitch is complete:
FolderPickerFeature → ChunkReviewFeature → StitchProgressFeature

// Audio is complete:
AudioFilePickerFeature → AudioPreviewFeature → AudioExtractionProgressFeature

// They don't share state, don't import each other
```

**Benefits:**
- Easy to add new tools (just add new case to AppFeature, new flow feature)
- Each tool testable in isolation
- No coupling complexity

### Pattern 2: Coordinator Feature (Flow Router)

**What:** A parent reducer that routes between sequential child screens.

**When:** Feature has 2+ screens with state transitions.

**Example:**
```swift
@Reducer
struct AudioFlowFeature {
    var state: State  // holds picker, preview, progress

    var body: some ReducerOf<Self> {
        Scope { AudioFilePickerFeature() }
        Reduce { state, action in
            // picker selection → create preview
            // preview approval → create progress
        }
        .ifLet(\.preview) { AudioPreviewFeature() }
        .ifLet(\.progress) { AudioExtractionProgressFeature() }
    }
}
```

**Benefits:** Encapsulates flow logic; clear state transitions.

### Pattern 3: Process-Based Subprocess (ffmpeg)

**What:** Synchronous Process invocation for long-running tasks.

**When:** Long operations (30-60 seconds) where thread blocking is acceptable.

**Example:**
```swift
let process = Process()
process.executableURL = URL(fileURLWithPath: ffmpegPath)
process.arguments = [...ffmpeg flags...]
try process.run()
process.waitUntilExit()
guard process.terminationStatus == 0 else { throw error }
```

**Benefits:** Simple, no external dependencies, proven in v1.0.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Shared State Between Tools

**What:** Trying to reuse AudioFilePickerFeature in multiple tools.

**Why bad:** Couples tools; hard to test independently.

**Instead:** Each tool has its own picker feature.

### Anti-Pattern 2: Tool Imports AppFeature

**What:** AudioExtractionProgressFeature tries to send AppFeature actions.

**Why bad:** Creates circular dependency; breaks encapsulation.

**Instead:** Send action up to parent (AudioFlowFeature), which passes to AppFeature.

### Anti-Pattern 3: Calling Process from View

**What:** SwiftUI view directly invokes ffmpeg via Process.

**Why bad:** Blocks UI thread; hard to test.

**Instead:** TCA reducer calls AudioExtractor in .run effect; view observes state.

### Anti-Pattern 4: Ignoring Process Errors

**What:** Assuming ffmpeg always succeeds.

**Why bad:** User sees cryptic errors.

**Instead:** Catch exceptions, map to user-friendly error messages (ChunkStitcherError pattern).

---

## File Organization

### Current Structure (Keep as-is)

```
GoProStitcher/
├── Features/
│   ├── ChunkReview/
│   │   ├── ChunkReviewFeature.swift
│   │   ├── ChunkReviewView.swift
│   │   └── ChunkPreviewModal.swift
│   ├── FolderPicker/
│   │   ├── FolderPickerFeature.swift
│   │   └── FolderPickerView.swift
│   └── StitchProgress/
│       ├── StitchProgressFeature.swift
│       └── StitchProgressView.swift
```

### New Structure (Add)

```
GoProStitcher/
├── Features/
│   ├── HomeScreen/              [NEW]
│   │   ├── HomeScreenFeature.swift
│   │   └── HomeScreenView.swift
│   │
│   ├── StitchFlow/              [NEW wrapper]
│   │   ├── StitchFlowFeature.swift
│   │   ├── StitchFlowView.swift
│   │   └── (existing features stay here)
│   │
│   └── AudioExtraction/         [NEW]
│       ├── AudioFilePickerFeature.swift
│       ├── AudioFilePickerView.swift
│       ├── AudioPreviewFeature.swift
│       ├── AudioPreviewView.swift
│       ├── AudioExtractionProgressFeature.swift
│       └── AudioExtractionProgressView.swift
│
├── AppFeature.swift             [UPDATED: add home + audio routing]
├── ContentView.swift            [UPDATED: conditional rendering]
└── ... other files
```

**Reasoning:** HomeScreen and tool flows are clearly separated. Easy to understand navigation.

---

## Testing Strategy

### Unit Tests (Isolated Reducer Testing)

```swift
// HomeScreenFeatureTests
func testStitchButtonTapped() {
    // HomeScreenFeature just sends action; no state change
    let store = TestStore(initialState: HomeScreenFeature.State()) {
        HomeScreenFeature()
    }
    await store.send(.stitchButtonTapped) {
        // No state change in HomeScreenFeature itself
    }
}

// AudioFlowFeatureTests
func testFileSelectionTransitionsToPreview() {
    let store = TestStore(initialState: AudioFlowFeature.State()) {
        AudioFlowFeature()
    }
    let testURL = URL(fileURLWithPath: "/tmp/test.mp4")

    await store.send(.filePicker(.fileSelected(testURL))) {
        $0.preview = AudioPreviewFeature.State(sourceURL: testURL)
    }
}
```

### Integration Tests (End-to-End Flow)

```swift
// AppFeatureNavigationTests
func testNavigateFromHomeToAudio() {
    let store = TestStore(initialState: AppFeature.State()) {
        AppFeature()
    }

    // Home screen visible initially
    assert(store.state.audioFlow == nil)

    // User taps "Extract Audio"
    await store.send(.homeScreen(.audioButtonTapped)) {
        $0.audioFlow = AudioFlowFeature.State()
    }

    // Audio flow is now active
    assert(store.state.audioFlow != nil)
}
```

### View Previews

```swift
#Preview {
    HomeScreenView(
        store: Store(initialState: HomeScreenFeature.State()) {
            HomeScreenFeature()
        }
    )
}
```

---

## Migration Path (v1.0 → v1.1)

### Phase 1: Non-Breaking Navigation Setup
1. Create HomeScreenFeature + HomeScreenView
2. Update AppFeature to add home + audio routing (keep stitch flow as-is)
3. Update ContentView to route via AppFeature
4. **Test:** App launches to home screen; both buttons functional (stitch already works, audio is placeholder)

### Phase 2: Extract StitchFlow (Pure Refactor)
1. Create StitchFlowFeature, copy current AppFeature logic into it
2. Move FolderPicker/ChunkReview/StitchProgress into StitchFlow/ directory
3. Update AppFeature to use StitchFlowFeature
4. **Test:** Stitch flow works identically; no behavior changes

### Phase 3: Build AudioFlow (Independent)
1. Create AudioFilePickerFeature
2. Create AudioPreviewFeature
3. Create AudioExtractionProgressFeature
4. Create AudioFlowFeature coordinator
5. Wire into AppFeature
6. **Test:** Audio extraction works end-to-end

### Phase 4: Polish
1. Add back buttons to tool screens
2. Update app display name to "GoPro Toolkit"
3. Final integration testing

**No breaking changes to v1.0.** Stitch continues to work exactly as before.

---

## Scalability Considerations

| Aspect | 2 Tools (Now) | 5+ Tools (Future) | 10+ Tools |
|--------|--------------|------------------|-----------|
| **AppFeature size** | Small (2 routes) | Grows slightly (5 routes) | Consider AppCoordinator split |
| **HomeScreen** | Simple enum routing | Still simple | May group tools by category |
| **Tool Independence** | ✓ Easy to test | ✓ Still isolated | ✓ No complexity increase |
| **File organization** | Clear | Clear | May add Tools/ directory level |

**Recommendation:** Current pattern scales to 5-10 tools easily. If adding 15+ tools, consider:
- Grouping tools by category in HomeScreen
- Splitting AppFeature into AppCoordinator + AppRouter
- But this is a future optimization; not needed now

---

## Sources & References

### TCA Composition Patterns
- TCA documentation: Scope, ifLet, Reduce patterns
- v1.0 reference: `AppFeature.swift`, `StitchProgressFeature.swift`

### Process Management
- Swift Foundation: `Process` class documentation
- v1.0 reference: `ChunkStitcher.swift` (ffmpeg subprocess pattern)

### Stack Specifications
- `.planning/research/STACK.md` — ffmpeg flags, technical decisions

---

**Summary:** V1.1 architecture is straightforward TCA composition. Independent tool flows routed from home screen. No new architectural paradigms; proven v1.0 patterns applied to multi-tool structure. Kit layer uses Process-based ffmpeg invocation (same as v1.0). Easy to test, extend, and maintain.

Last updated: 2026-03-18
