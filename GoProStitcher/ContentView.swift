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
                    VStack(spacing: 0) {
                        // Back button row
                        HStack {
                            RetroButton(title: "< BACK") { store.send(.backToHome) }
                            Spacer()
                        }
                        .padding(RetroSpacing.md)
                        .background(RetroColor.beigeBackground)

                        FolderPickerView(
                            store: store.scope(state: \.folderPicker, action: \.folderPicker)
                        )
                    }
                    .background(RetroColor.beigeBackground)
                }

            case .audio:
                if store.audioExtraction != nil {
                    VStack(spacing: 0) {
                        HStack {
                            RetroButton(title: "< BACK") { store.send(.backToHome) }
                            Spacer()
                        }
                        .padding(RetroSpacing.md)
                        .background(RetroColor.beigeBackground)

                        AudioExtractionView(
                            store: store.scope(state: \.audioExtraction!, action: \.audioExtraction)
                        )
                    }
                    .background(RetroColor.beigeBackground)
                } else {
                    VStack(spacing: 0) {
                        HStack {
                            RetroButton(title: "< BACK") { store.send(.backToHome) }
                            Spacer()
                        }
                        .padding(RetroSpacing.md)
                        .background(RetroColor.beigeBackground)

                        AudioFilePickerView(
                            store: store.scope(state: \.audioPicker, action: \.audioPicker)
                        )
                    }
                    .background(RetroColor.beigeBackground)
                }
            }
        }
        .background(RetroColor.beigeBackground.ignoresSafeArea())
    }
}

#Preview {
    ContentView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
