import ComposableArchitecture
import SwiftUI

@main
struct GoProStitcherApp: App {
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}
