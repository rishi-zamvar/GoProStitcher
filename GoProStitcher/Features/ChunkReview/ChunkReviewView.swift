import AppKit
import ComposableArchitecture
import GoProStitcherKit
import Perception
import SwiftUI

// MARK: - URL+Identifiable

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - ChunkRowView

private struct ChunkRowView: View {
    let chunk: ScannedChunk
    let metadata: ChunkMetadata?

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail or placeholder
            Group {
                if let image = metadata?.thumbnail {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .foregroundStyle(Color.secondary.opacity(0.25))
                        .overlay {
                            Image(systemName: "film")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                }
            }
            .frame(width: 40, height: 30)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Filename + metadata
            VStack(alignment: .leading, spacing: 2) {
                Text(chunk.chunk.filename)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(metadataString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var metadataString: String {
        guard let meta = metadata else {
            return "Loading…"
        }
        let duration = formattedDuration(meta.duration)
        let size = formattedSize(chunk.sizeBytes)
        let resolution = formattedResolution(meta.resolution)
        return "\(duration) — \(size) — \(resolution)"
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        if s < 60 {
            return "\(s)s"
        }
        return "\(s / 60)m \(s % 60)s"
    }

    private func formattedSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private func formattedResolution(_ size: CGSize) -> String {
        let w = Int(size.width)
        let h = Int(size.height)
        return "\(w)\u{00D7}\(h)"
    }
}

// MARK: - ChunkReviewView

struct ChunkReviewView: View {
    @Perception.Bindable var store: StoreOf<ChunkReviewFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Review Clips")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(store.chunks.count) clip\(store.chunks.count == 1 ? "" : "s") detected — drag to reorder")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Start Stitching") {
                    store.send(.startStitching)
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.chunks.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Chunk list
            List {
                ForEach(store.chunks, id: \.url) { chunk in
                    ChunkRowView(
                        chunk: chunk,
                        metadata: store.metadata[chunk.url]
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        store.send(.chunkTapped(chunk.url))
                    }
                }
                .onMove { from, to in
                    store.send(.chunksReordered(from: from, to: to))
                }
            }
            .listStyle(.plain)
        }
        .frame(minWidth: 520, minHeight: 360)
        .onAppear {
            store.send(.loadAllMetadata)
        }
        .sheet(isPresented: Binding(
            get: { store.selectedPreviewURL != nil },
            set: { if !$0 { store.send(.previewDismissed) } }
        )) {
            if let url = store.selectedPreviewURL {
                ChunkPreviewModal(url: url) {
                    store.send(.previewDismissed)
                }
            }
        }
    }
}

#Preview {
    ChunkReviewView(
        store: Store(
            initialState: ChunkReviewFeature.State(chunks: [])
        ) {
            ChunkReviewFeature()
        }
    )
}
