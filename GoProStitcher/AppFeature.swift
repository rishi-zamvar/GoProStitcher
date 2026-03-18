import ComposableArchitecture
import GoProStitcherKit

// MARK: - AppFeature

/// Root TCA reducer that manages top-level navigation between the Home screen,
/// FolderPicker/ChunkReview/StitchProgress (stitch tool), and the AudioExtraction flow.
@Reducer
struct AppFeature {

    enum ActiveTool: Equatable { case stitch, audio }

    @ObservableState
    struct State: Equatable {
        /// Home screen state (always present).
        var home = HomeFeature.State()
        var folderPicker = FolderPickerFeature.State()
        /// Non-nil when the user has selected a folder and is reviewing chunks.
        var chunkReview: ChunkReviewFeature.State? = nil
        /// Non-nil once the user taps "Start Stitching" from the review screen.
        var stitchProgress: StitchProgressFeature.State? = nil
        /// Audio picker state (always present; controls NSOpenPanel).
        var audioPicker = AudioFilePickerFeature.State()
        /// Non-nil once the user selects an MP4 — drives the extraction screen.
        var audioExtraction: AudioExtractionFeature.State? = nil
        /// Which tool (if any) the user has navigated into.
        var activeTool: ActiveTool? = nil
    }

    enum Action {
        case home(HomeFeature.Action)
        case folderPicker(FolderPickerFeature.Action)
        case chunkReview(ChunkReviewFeature.Action)
        case stitchProgress(StitchProgressFeature.Action)
        case audioPicker(AudioFilePickerFeature.Action)
        case audioExtraction(AudioExtractionFeature.Action)
        case backToHome
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }
        Scope(state: \.folderPicker, action: \.folderPicker) {
            FolderPickerFeature()
        }
        Scope(state: \.audioPicker, action: \.audioPicker) {
            AudioFilePickerFeature()
        }
        Reduce { state, action in
            switch action {
            case .home(.stitchVideoTapped):
                state.activeTool = .stitch
                return .none

            case .home(.extractAudioTapped):
                state.activeTool = .audio
                return .none

            case .home:
                return .none

            case .backToHome:
                state.activeTool = nil
                state.chunkReview = nil
                state.stitchProgress = nil
                state.audioPicker = AudioFilePickerFeature.State()
                state.audioExtraction = nil
                state.folderPicker = FolderPickerFeature.State()
                return .none

            case let .folderPicker(.scanCompleted(.success(chunks))):
                state.chunkReview = ChunkReviewFeature.State(chunks: chunks)
                return .none

            case .chunkReview(.startStitching):
                guard let review = state.chunkReview else { return .none }
                state.stitchProgress = StitchProgressFeature.State(chunks: review.chunks)
                return .send(.stitchProgress(.startStitch))

            case .chunkReview:
                return .none

            case .folderPicker:
                return .none

            case .stitchProgress:
                return .none

            case let .audioPicker(.fileSelected(url)):
                let filename = url.lastPathComponent
                state.audioExtraction = AudioExtractionFeature.State(
                    sourceURL: url,
                    filename: filename
                )
                return .send(.audioExtraction(.startExtraction))

            case .audioPicker(.userCancelledPicker):
                state.activeTool = nil
                return .none

            case .audioPicker:
                return .none

            case .audioExtraction:
                return .none
            }
        }
        .ifLet(\.chunkReview, action: \.chunkReview) {
            ChunkReviewFeature()
        }
        .ifLet(\.stitchProgress, action: \.stitchProgress) {
            StitchProgressFeature()
        }
        .ifLet(\.audioExtraction, action: \.audioExtraction) {
            AudioExtractionFeature()
        }
    }
}
