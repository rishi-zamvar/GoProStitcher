import ComposableArchitecture
import SwiftUI

struct ContentView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        WithPerceptionTracking {
            switch store.activeTool {
            case .none:
                HomeView(store: store)

            case .stitch:
                if store.stitchProgress != nil {
                    StitchProgressView(
                        store: store.scope(state: \.stitchProgress!, action: \.stitchProgress)
                    )
                } else if store.chunkReview != nil {
                    ChunkReviewView(
                        store: store.scope(state: \.chunkReview!, action: \.chunkReview)
                    )
                } else {
                    VStack {
                        Button("< Back") { store.send(.backToHome) }
                            .padding(.top, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        FolderPickerView(
                            store: store.scope(state: \.folderPicker, action: \.folderPicker)
                        )
                    }
                    .padding(.horizontal, 16)
                }

            case .audio:
                if store.audioExtraction != nil {
                    AudioExtractionView(
                        store: store.scope(state: \.audioExtraction!, action: \.audioExtraction)
                    )
                } else {
                    // Show file picker immediately; cancelling returns to home
                    AudioFilePickerView(
                        store: store.scope(state: \.audioPicker, action: \.audioPicker)
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
