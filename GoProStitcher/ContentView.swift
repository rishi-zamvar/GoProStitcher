import ComposableArchitecture
import SwiftUI

struct ContentView: View {
    var body: some View {
        FolderPickerView(
            store: Store(initialState: FolderPickerFeature.State()) {
                FolderPickerFeature()
            }
        )
    }
}

#Preview {
    ContentView()
}
