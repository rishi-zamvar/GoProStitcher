import AppKit
import ComposableArchitecture
import UniformTypeIdentifiers

@Reducer
struct AudioFilePickerFeature {
    @ObservableState
    struct State: Equatable {
        var isLoading: Bool = false
    }

    enum Action {
        case selectFileButtonTapped
        case fileSelected(URL)
        case userCancelledPicker
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .selectFileButtonTapped:
                state.isLoading = true
                return .run { send in
                    let url = await MainActor.run { () -> URL? in
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = true
                        panel.canChooseDirectories = false
                        panel.allowsMultipleSelection = false
                        panel.allowedContentTypes = [.mpeg4Movie]
                        panel.title = "Select MP4 File"
                        panel.prompt = "Select"
                        let response = panel.runModal()
                        return response == .OK ? panel.url : nil
                    }
                    if let url {
                        await send(.fileSelected(url))
                    } else {
                        await send(.userCancelledPicker)
                    }
                }
            case .fileSelected:
                state.isLoading = false
                return .none
            case .userCancelledPicker:
                state.isLoading = false
                return .none
            }
        }
    }
}
