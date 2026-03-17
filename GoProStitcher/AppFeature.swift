import ComposableArchitecture
import GoProStitcherKit

// MARK: - AppFeature

/// Root TCA reducer that manages top-level navigation between FolderPicker and ChunkReview.
@Reducer
struct AppFeature {

    @ObservableState
    struct State: Equatable {
        var folderPicker = FolderPickerFeature.State()
        var chunkReview: ChunkReviewFeature.State? = nil
    }

    enum Action {
        case folderPicker(FolderPickerFeature.Action)
        case chunkReview(ChunkReviewFeature.Action)
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
            case .chunkReview:
                return .none
            case .folderPicker:
                return .none
            }
        }
        .ifLet(\.chunkReview, action: \.chunkReview) {
            ChunkReviewFeature()
        }
    }
}
