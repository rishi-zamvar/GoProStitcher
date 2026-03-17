import ComposableArchitecture
import GoProStitcherKit

/// TCA reducer that manages the stitching pipeline lifecycle.
///
/// Operation order: save manifest (records chunk boundaries for reversion),
/// then stitch (appends chunks[1..N-1] onto chunks[0] and removes source files).
/// No zip files created — zero extra storage beyond a tiny JSON manifest.
@Reducer
struct StitchProgressFeature {

    @ObservableState
    struct State: Equatable {
        /// Ordered list of chunks to process (matches the order from ChunkReviewFeature).
        var chunks: [ScannedChunk]
        /// Current phase of the pipeline.
        var phase: StitchPhase = .savingManifest
        /// True once the full pipeline finishes without error.
        var isComplete: Bool = false
        /// Non-nil when the pipeline fails; contains the localized error description.
        var errorMessage: String? = nil
    }

    enum Action {
        /// Kick off the manifest-then-stitch pipeline.
        case startStitch
        /// Fired per-file as each step progresses.
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
                    let sourceDir = chunkURLs[0].deletingLastPathComponent()
                    let manifestURL = sourceDir.appendingPathComponent("stitch_manifest.json")

                    do {
                        // Step 1 — Save manifest: record chunk boundaries for reversion.
                        await send(.phaseUpdated(.savingManifest))
                        try ChunkArchiver.archive(chunks: chunkURLs, into: manifestURL)

                        // Step 2 — Stitch: append chunks[1..N-1] onto chunks[0] in-place.
                        guard chunkURLs.count >= 2 else {
                            await send(.stitchCompleted)
                            return
                        }
                        for (index, sourceURL) in chunkURLs.dropFirst().enumerated() {
                            let name = sourceURL.lastPathComponent
                            await send(.phaseUpdated(.stitching(fileIndex: index + 1, fileName: name)))
                            // Stitch one file at a time so progress updates are real
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
