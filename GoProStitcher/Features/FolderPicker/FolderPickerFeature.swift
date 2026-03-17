import AppKit
import ComposableArchitecture
import GoProStitcherKit

@Reducer
struct FolderPickerFeature {

    @ObservableState
    struct State: Equatable {
        var scanResult: FolderScanResult? = nil
        var isLoading: Bool = false
    }

    enum Action {
        case selectFolderButtonTapped
        case folderSelected(URL)
        case scanCompleted(FolderScanResult)
        case userCancelledPicker
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .selectFolderButtonTapped:
                state.isLoading = true
                return .run { send in
                    let url = await MainActor.run { () -> URL? in
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.allowsMultipleSelection = false
                        panel.title = "Select GoPro Folder"
                        panel.prompt = "Select"
                        let response = panel.runModal()
                        return response == .OK ? panel.url : nil
                    }
                    if let url {
                        await send(.folderSelected(url))
                    } else {
                        await send(.userCancelledPicker)
                    }
                }

            case let .folderSelected(url):
                return .run { send in
                    let result = FolderScanner.scan(url: url)
                    await send(.scanCompleted(result))
                }

            case let .scanCompleted(result):
                state.scanResult = result
                state.isLoading = false
                return .none

            case .userCancelledPicker:
                state.isLoading = false
                return .none
            }
        }
    }
}

// MARK: - FolderScanResult Equatable conformance

extension FolderScanResult: Equatable {
    public static func == (lhs: FolderScanResult, rhs: FolderScanResult) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            return true
        case (.noGoProFiles, .noGoProFiles):
            return true
        case let (.success(lhsChunks), .success(rhsChunks)):
            return lhsChunks == rhsChunks
        default:
            return false
        }
    }
}
