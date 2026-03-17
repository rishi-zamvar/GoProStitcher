import ComposableArchitecture
import GoProStitcherKit

// MARK: - AppFeature

/// Root TCA reducer that manages top-level navigation between FolderPicker, ChunkReview,
/// and StitchProgress screens.
@Reducer
struct AppFeature {

    @ObservableState
    struct State: Equatable {
        var folderPicker = FolderPickerFeature.State()
        /// Non-nil when the user has selected a folder and is reviewing chunks.
        var chunkReview: ChunkReviewFeature.State? = nil
        /// Non-nil once the user taps "Start Stitching" from the review screen.
        var stitchProgress: StitchProgressFeature.State? = nil
    }

    enum Action {
        case folderPicker(FolderPickerFeature.Action)
        case chunkReview(ChunkReviewFeature.Action)
        case stitchProgress(StitchProgressFeature.Action)
    }

    var body: some ReducerOf<Self> {
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

            case .chunkReview:
                return .none

            case .folderPicker:
                return .none

            case .stitchProgress:
                return .none
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
