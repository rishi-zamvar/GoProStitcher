import AppKit
import ComposableArchitecture
import Foundation
import GoProStitcherKit

// MARK: - ChunkMetadata

/// Metadata loaded asynchronously for a single GoPro chunk.
public struct ChunkMetadata: Equatable {
    public let duration: TimeInterval
    public let resolution: CGSize
    public let thumbnail: NSImage?

    public init(duration: TimeInterval, resolution: CGSize, thumbnail: NSImage?) {
        self.duration = duration
        self.resolution = resolution
        self.thumbnail = thumbnail
    }

    /// Equatable ignores thumbnail — NSImage does not conform to Equatable.
    public static func == (lhs: ChunkMetadata, rhs: ChunkMetadata) -> Bool {
        lhs.duration == rhs.duration && lhs.resolution == rhs.resolution
    }
}

// MARK: - ChunkReviewFeature

@Reducer
struct ChunkReviewFeature {

    @ObservableState
    struct State: Equatable {
        /// Mutable ordered list of chunks (user can drag to reorder).
        var chunks: [ScannedChunk]
        /// Non-nil when a preview modal is shown for a specific chunk URL.
        var selectedPreviewURL: URL? = nil
        /// Loaded metadata, keyed by chunk URL.
        var metadata: [URL: ChunkMetadata] = [:]
    }

    enum Action {
        /// User dragged a row; apply Array.move semantics.
        case chunksReordered(from: IndexSet, to: Int)
        /// User tapped a chunk row to open preview.
        case chunkTapped(URL)
        /// User dismissed the preview modal.
        case previewDismissed
        /// Trigger async metadata load for a single chunk URL.
        case loadMetadata(URL)
        /// Dispatched by loadMetadata effect when metadata is ready.
        case metadataLoaded(URL, ChunkMetadata)
        /// Trigger loadMetadata for all chunks (called on view appear).
        case loadAllMetadata
        /// User tapped "Start Stitching". AppFeature intercepts this to navigate to progress screen.
        case startStitching
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            case let .chunksReordered(from, to):
                state.chunks.move(fromOffsets: from, toOffset: to)
                return .none

            case let .chunkTapped(url):
                state.selectedPreviewURL = url
                return .none

            case .previewDismissed:
                state.selectedPreviewURL = nil
                return .none

            case let .loadMetadata(url):
                return .run { [url] send in
                    let duration = await AVMetadataReader.duration(url: url) ?? 0
                    let resolution = await AVMetadataReader.resolution(url: url) ?? .zero
                    let thumbnail = await AVMetadataReader.thumbnail(url: url)
                    let meta = ChunkMetadata(
                        duration: duration,
                        resolution: resolution,
                        thumbnail: thumbnail
                    )
                    await send(.metadataLoaded(url, meta))
                }

            case let .metadataLoaded(url, meta):
                state.metadata[url] = meta
                return .none

            case .loadAllMetadata:
                let effects = state.chunks.map { chunk in
                    Effect<Action>.send(.loadMetadata(chunk.url))
                }
                return .merge(effects)

            case .startStitching:
                // AppFeature intercepts this action to navigate to the progress screen.
                return .none
            }
        }
    }
}
