import ComposableArchitecture
import SwiftUI

struct ContentView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        if store.stitchProgress != nil {
            StitchProgressView(
                store: store.scope(state: \.stitchProgress!, action: \.stitchProgress)
            )
        } else if store.chunkReview != nil {
            ChunkReviewView(
                store: store.scope(state: \.chunkReview!, action: \.chunkReview)
            )
        } else {
            FolderPickerView(
                store: store.scope(state: \.folderPicker, action: \.folderPicker)
            )
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
