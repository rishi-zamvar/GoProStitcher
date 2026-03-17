import ComposableArchitecture
import GoProStitcherKit

/// TCA reducer that manages the stitching + archiving pipeline lifecycle.
///
/// Operation order: archive all original chunks first (preserves originals as zips),
/// then stitch (appends chunks[1..N-1] onto chunks[0] and removes source files).
@Reducer
struct StitchProgressFeature {

    @ObservableState
    struct State: Equatable {
        /// Ordered list of chunks to process (matches the order from ChunkReviewFeature).
        var chunks: [ScannedChunk]
        /// Current phase of the pipeline.
        var phase: StitchPhase = .archiving(fileIndex: 0, fileName: "")
        /// True once the full archive-then-stitch pipeline finishes without error.
        var isComplete: Bool = false
        /// Non-nil when the pipeline fails; contains the localized error description.
        var errorMessage: String? = nil
    }

    enum Action {
        /// Kick off the archive-then-stitch pipeline.
        case startStitch
        /// Fired per-file as each archive or stitch step begins.
        case phaseUpdated(StitchPhase)
        /// Fired when the full pipeline completes successfully.
        case stitchCompleted
        /// Fired when the pipeline encounters an error.
        case stitchFailed(String)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            case .startStitch:
                let chunks = state.chunks
                return .run { send in
                    let chunkURLs = chunks.map { $0.url }
                    guard !chunkURLs.isEmpty else {
                        await send(.stitchFailed("No chunks to process."))
                        return
                    }
                    let archiveDir = chunkURLs[0]
                        .deletingLastPathComponent()
                        .appendingPathComponent("archive")

                    do {
                        // Step 1 — Archive: zip every original chunk before stitching removes them.
                        try ChunkArchiver.archive(chunks: chunkURLs, into: archiveDir) { idx, _ in
                            Task {
                                let name = chunkURLs[idx - 1].lastPathComponent
                                await send(.phaseUpdated(.archiving(fileIndex: idx - 1, fileName: name)))
                            }
                        }

                        // Step 2 — Stitch: append chunks[1..N-1] onto chunks[0] in-place.
                        for (index, sourceURL) in chunkURLs.dropFirst().enumerated() {
                            let name = sourceURL.lastPathComponent
                            await send(.phaseUpdated(.stitching(fileIndex: index + 1, fileName: name)))
                        }
                        try ChunkStitcher.stitch(chunks: chunkURLs)

                        await send(.stitchCompleted)
                    } catch {
                        await send(.stitchFailed(error.localizedDescription))
                    }
                }

            case let .phaseUpdated(phase):
                state.phase = phase
                return .none

            case .stitchCompleted:
                state.isComplete = true
                state.phase = .complete
                return .none

            case let .stitchFailed(message):
                state.errorMessage = message
                state.phase = .failed(message)
                return .none
            }
        }
    }
}
