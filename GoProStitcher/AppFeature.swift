import ComposableArchitecture
import GoProStitcherKit

// MARK: - AppFeature

/// Root TCA reducer that manages top-level navigation between FolderPicker, ChunkReview,
/// StitchProgress screens, and the AudioExtraction flow.
@Reducer
struct AppFeature {

    @ObservableState
    struct State: Equatable {
        var folderPicker = FolderPickerFeature.State()
        /// Non-nil when the user has selected a folder and is reviewing chunks.
        var chunkReview: ChunkReviewFeature.State? = nil
        /// Non-nil once the user taps "Start Stitching" from the review screen.
        var stitchProgress: StitchProgressFeature.State? = nil
        /// Audio picker state (always present; controls NSOpenPanel).
        var audioPicker = AudioFilePickerFeature.State()
        /// Non-nil once the user selects an MP4 — drives the extraction screen.
        var audioExtraction: AudioExtractionFeature.State? = nil
        /// True when the user explicitly wants to enter the audio tool flow.
        var showAudioPicker: Bool = false
    }

    enum Action {
        case folderPicker(FolderPickerFeature.Action)
        case chunkReview(ChunkReviewFeature.Action)
        case stitchProgress(StitchProgressFeature.Action)
        case audioPicker(AudioFilePickerFeature.Action)
        case audioExtraction(AudioExtractionFeature.Action)
        case showAudioPickerTapped
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.folderPicker, action: \.folderPicker) {
            FolderPickerFeature()
        }
        Scope(state: \.audioPicker, action: \.audioPicker) {
            AudioFilePickerFeature()
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

            case .chunkReview:
                return .none

            case .folderPicker:
                return .none

            case .stitchProgress:
                return .none

            case .showAudioPickerTapped:
                state.showAudioPicker = true
                return .none

            case let .audioPicker(.fileSelected(url)):
                state.showAudioPicker = false
                let filename = url.lastPathComponent
                state.audioExtraction = AudioExtractionFeature.State(
                    sourceURL: url,
                    filename: filename
                )
                return .send(.audioExtraction(.startExtraction))

            case .audioPicker(.userCancelledPicker):
                state.showAudioPicker = false
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
