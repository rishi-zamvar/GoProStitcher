import ComposableArchitecture
import GoProStitcherKit
import SwiftUI

struct FolderPickerView: View {
    let store: StoreOf<FolderPickerFeature>

    var body: some View {
        VStack(spacing: RetroSpacing.lg) {
            // Header
            VStack(spacing: RetroSpacing.sm) {
                Text("GoPro Toolkit")
                    .font(RetroFont.bold(24))
                    .foregroundColor(RetroColor.black)
                Text("Select a folder containing GoPro video files")
                    .font(RetroFont.regular(13))
                    .foregroundColor(RetroColor.muted)
                    .multilineTextAlignment(.center)
            }

            // Select Folder Button
            RetroButton(
                title: store.isLoading ? "SCANNING..." : "SELECT FOLDER",
                action: { store.send(.selectFolderButtonTapped) },
                isDisabled: store.isLoading
            )

            // Loading indicator
            if store.isLoading {
                Text("[ LOADING... ]")
                    .font(RetroFont.regular(12))
                    .foregroundColor(RetroColor.muted)
            }

            // Result display
            if let result = store.scanResult {
                resultView(for: result)
                    .transition(.opacity)
            }

            Spacer()
        }
        .padding(RetroSpacing.xl)
        .frame(minWidth: 420, minHeight: 280)
        .background(RetroColor.beigeBackground)
        .animation(.linear(duration: 0.1), value: store.scanResult == nil)
        .animation(.linear(duration: 0.1), value: store.isLoading)
    }

    @ViewBuilder
    private func resultView(for result: FolderScanResult) -> some View {
        switch result {
        case let .success(chunks):
            let totalSize = chunks.reduce(0) { $0 + $1.sizeBytes }
            RetroCard {
                HStack(spacing: RetroSpacing.sm) {
                    Text("✓")
                        .font(RetroFont.bold(18))
                        .foregroundColor(RetroColor.black)
                    VStack(alignment: .leading, spacing: RetroSpacing.xs) {
                        Text("\(chunks.count) GoPro file\(chunks.count == 1 ? "" : "s") found")
                            .font(RetroFont.bold(13))
                            .foregroundColor(RetroColor.black)
                        Text(formattedSize(totalSize))
                            .font(RetroFont.regular(11))
                            .foregroundColor(RetroColor.muted)
                    }
                    Spacer()
                }
                .padding(RetroSpacing.sm)
            }

        case .empty:
            RetroCard {
                HStack(spacing: RetroSpacing.sm) {
                    Text("✗")
                        .font(RetroFont.bold(18))
                        .foregroundColor(RetroColor.accentRed)
                    Text("No files found in selected folder")
                        .font(RetroFont.bold(13))
                        .foregroundColor(RetroColor.accentRed)
                    Spacer()
                }
                .padding(RetroSpacing.sm)
            }

        case .noGoProFiles:
            RetroCard {
                HStack(spacing: RetroSpacing.sm) {
                    Text("✗")
                        .font(RetroFont.bold(18))
                        .foregroundColor(RetroColor.accentRed)
                    Text("No GoPro files found in selected folder")
                        .font(RetroFont.bold(13))
                        .foregroundColor(RetroColor.accentRed)
                    Spacer()
                }
                .padding(RetroSpacing.sm)
            }
        }
    }

    private func formattedSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

#Preview {
    FolderPickerView(
        store: Store(initialState: FolderPickerFeature.State()) {
            FolderPickerFeature()
        }
    )
}
