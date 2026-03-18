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
        HStack(spacing: RetroSpacing.sm) {
            // Thumbnail or placeholder
            Group {
                if let image = metadata?.thumbnail {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .foregroundColor(RetroColor.beigeSecondary)
                        .overlay {
                            Text("[?]")
                                .font(RetroFont.caption)
                                .foregroundColor(RetroColor.muted)
                        }
                }
            }
            .frame(width: 40, height: 30)
            .clipShape(Rectangle())
            .overlay(Rectangle().stroke(RetroColor.black, lineWidth: 1))

            // Filename + metadata
            VStack(alignment: .leading, spacing: RetroSpacing.xs) {
                Text(chunk.chunk.filename)
                    .font(RetroFont.body)
                    .foregroundColor(RetroColor.black)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(metadataString)
                    .font(RetroFont.caption)
                    .foregroundColor(RetroColor.muted)
            }

            Spacer()
        }
        .padding(.vertical, RetroSpacing.xs)
    }

    private var metadataString: String {
        guard let meta = metadata else {
            return "Loading..."
        }
        let duration = formattedDuration(meta.duration)
        let size = formattedSize(chunk.sizeBytes)
        let resolution = formattedResolution(meta.resolution)
        return "\(duration) -- \(size) -- \(resolution)"
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
                VStack(alignment: .leading, spacing: RetroSpacing.xs) {
                    Text("REVIEW CLIPS")
                        .font(RetroFont.bold(18))
                        .foregroundColor(RetroColor.black)
                    Text("\(store.chunks.count) clip\(store.chunks.count == 1 ? "" : "s") detected — drag to reorder")
                        .font(RetroFont.regular(12))
                        .foregroundColor(RetroColor.muted)
                }
                Spacer()
                RetroButton(
                    title: "START STITCHING",
                    action: { store.send(.startStitching) },
                    isDisabled: store.chunks.isEmpty
                )
            }
            .padding(.horizontal, RetroSpacing.md)
            .padding(.vertical, RetroSpacing.sm)

            // Divider replacement — 2px black line
            Rectangle()
                .fill(RetroColor.black)
                .frame(height: 2)

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
                    .listRowBackground(RetroColor.beigeBackground)
                    .listRowSeparatorTint(RetroColor.beigeSecondary)
                }
                .onMove { from, to in
                    store.send(.chunksReordered(from: from, to: to))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(RetroColor.beigeBackground)
        }
        .background(RetroColor.beigeBackground)
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
