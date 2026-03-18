import ComposableArchitecture
import GoProStitcherKit
import SwiftUI

struct FolderPickerView: View {
    let store: StoreOf<FolderPickerFeature>

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("GoPro Toolkit")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Select a folder containing GoPro video files")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Select Folder Button
            Button(action: {
                store.send(.selectFolderButtonTapped)
            }) {
                HStack {
                    if store.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(store.isLoading ? "Scanning…" : "Select Folder")
                }
                .frame(minWidth: 140)
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.isLoading)

            // Result display
            if let result = store.scanResult {
                resultView(for: result)
                    .transition(.opacity)
            }

            Spacer()
        }
        .padding(32)
        .frame(minWidth: 420, minHeight: 280)
        .animation(.easeInOut(duration: 0.2), value: store.scanResult)
        .animation(.easeInOut(duration: 0.2), value: store.isLoading)
    }

    @ViewBuilder
    private func resultView(for result: FolderScanResult) -> some View {
        switch result {
        case let .success(chunks):
            let totalSize = chunks.reduce(0) { $0 + $1.sizeBytes }
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(chunks.count) GoPro file\(chunks.count == 1 ? "" : "s") found")
                        .fontWeight(.medium)
                    Text(formattedSize(totalSize))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))

        case .empty:
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.title2)
                Text("No files found in selected folder")
                    .fontWeight(.medium)
            }
            .padding(12)
            .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))

        case .noGoProFiles:
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.title2)
                Text("No GoPro files found in selected folder")
                    .fontWeight(.medium)
            }
            .padding(12)
            .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
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
