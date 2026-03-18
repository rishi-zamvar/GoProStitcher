import ComposableArchitecture
import SwiftUI

struct ContentView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        if store.audioExtraction != nil {
            AudioExtractionView(
                store: store.scope(state: \.audioExtraction!, action: \.audioExtraction)
            )
        } else if store.showAudioPicker {
            AudioFilePickerView(
                store: store.scope(state: \.audioPicker, action: \.audioPicker)
            )
        } else if store.stitchProgress != nil {
            StitchProgressView(
                store: store.scope(state: \.stitchProgress!, action: \.stitchProgress)
            )
        } else if store.chunkReview != nil {
            ChunkReviewView(
                store: store.scope(state: \.chunkReview!, action: \.chunkReview)
            )
        } else {
            VStack {
                FolderPickerView(
                    store: store.scope(state: \.folderPicker, action: \.folderPicker)
                )
                Button("Extract Audio from MP4") {
                    store.send(.showAudioPickerTapped)
                }
                .padding(.bottom, 16)
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
