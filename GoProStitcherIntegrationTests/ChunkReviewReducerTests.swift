import ComposableArchitecture
import GoProStitcherKit
import XCTest

@testable import GoProStitcher

// MARK: - Helpers

private func makeChunk(filename: String) -> ScannedChunk {
    let chunk = GoProNameParser.parse(filename)!
    return ScannedChunk(
        chunk: chunk,
        url: URL(fileURLWithPath: "/tmp/\(filename)"),
        sizeBytes: 1_000_000
    )
}

// MARK: - Tests

final class ChunkReviewReducerTests: XCTestCase {

    // [A, B, C] — move index 2 to 0 → [C, A, B]
    func testReorderMoveLastToFirst() async {
        let chunkA = makeChunk(filename: "GH010001.MP4")
        let chunkB = makeChunk(filename: "GH010002.MP4")
        let chunkC = makeChunk(filename: "GH010003.MP4")

        let store = TestStore(
            initialState: ChunkReviewFeature.State(chunks: [chunkA, chunkB, chunkC])
        ) {
            ChunkReviewFeature()
        }

        await store.send(.chunksReordered(from: IndexSet(integer: 2), to: 0)) { state in
            // TCA TestStore: mutate state to match expected result
            state.chunks = [chunkC, chunkA, chunkB]
        }
    }

    // [A, B, C] — move index 0 to 3 (end) → [B, C, A]
    func testReorderMoveFirstToEnd() async {
        let chunkA = makeChunk(filename: "GH010001.MP4")
        let chunkB = makeChunk(filename: "GH010002.MP4")
        let chunkC = makeChunk(filename: "GH010003.MP4")

        let store = TestStore(
            initialState: ChunkReviewFeature.State(chunks: [chunkA, chunkB, chunkC])
        ) {
            ChunkReviewFeature()
        }

        await store.send(.chunksReordered(from: IndexSet(integer: 0), to: 3)) { state in
            state.chunks = [chunkB, chunkC, chunkA]
        }
    }

    // chunkTapped(url) → selectedPreviewURL == url
    func testChunkTappedSetsPreviewURL() async {
        let chunkA = makeChunk(filename: "GH010001.MP4")
        let targetURL = chunkA.url

        let store = TestStore(
            initialState: ChunkReviewFeature.State(chunks: [chunkA])
        ) {
            ChunkReviewFeature()
        }

        await store.send(.chunkTapped(targetURL)) { state in
            state.selectedPreviewURL = targetURL
        }
    }

    // chunkTapped then previewDismissed → selectedPreviewURL == nil
    func testPreviewDismissedClearsURL() async {
        let chunkA = makeChunk(filename: "GH010001.MP4")
        let targetURL = chunkA.url

        let store = TestStore(
            initialState: ChunkReviewFeature.State(chunks: [chunkA])
        ) {
            ChunkReviewFeature()
        }

        await store.send(.chunkTapped(targetURL)) { state in
            state.selectedPreviewURL = targetURL
        }

        await store.send(.previewDismissed) { state in
            state.selectedPreviewURL = nil
        }
    }
}
