import XCTest
@testable import GoProStitcherKit

final class ChunkStitcherTests: XCTestCase {
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = try? TempDirectoryHelper.create()
        XCTAssertNotNil(tempDir, "Failed to create temp directory in setUp")
    }

    override func tearDown() {
        TempDirectoryHelper.cleanup(url: tempDir)
        tempDir = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeFile(at url: URL, byte: UInt8, count: Int) throws {
        let data = Data(repeating: byte, count: count)
        try data.write(to: url)
    }

    /// Copies the real MP4 fixture to a temp location with the given name.
    private func copyFixture(named name: String) throws -> URL {
        guard let fixtureURL = Bundle.module.url(forResource: "GH010001", withExtension: "MP4") else {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fixture not found"])
        }
        let dest = tempDir.appendingPathComponent(name)
        try FileManager.default.copyItem(at: fixtureURL, to: dest)
        return dest
    }

    // MARK: - ffmpeg concat stitching

    func testStitch_twoChunks_producesPlayableOutput() throws {
        let chunk1 = try copyFixture(named: "GH010001.MP4")
        let chunk2 = try copyFixture(named: "GH020001.MP4")

        let originalSize = try FileManager.default.attributesOfItem(atPath: chunk1.path)[.size] as? Int ?? 0

        try ChunkStitcher.stitch(chunks: [chunk1, chunk2])

        // Output should exist and be larger than a single chunk
        XCTAssertTrue(FileManager.default.fileExists(atPath: chunk1.path), "Stitched output should exist at chunk1 path")
        let stitchedSize = try FileManager.default.attributesOfItem(atPath: chunk1.path)[.size] as? Int ?? 0
        XCTAssertGreaterThan(stitchedSize, originalSize, "Stitched file should be larger than single chunk")
    }

    func testStitch_sourcesRemovedAfterStitch() throws {
        let chunk1 = try copyFixture(named: "GH010001.MP4")
        let chunk2 = try copyFixture(named: "GH020001.MP4")

        try ChunkStitcher.stitch(chunks: [chunk1, chunk2])

        XCTAssertFalse(FileManager.default.fileExists(atPath: chunk2.path), "Source chunk2 should be removed")
        XCTAssertTrue(FileManager.default.fileExists(atPath: chunk1.path), "Destination should still exist")
    }

    func testStitch_threeChunks_allSourcesRemoved() throws {
        let chunk1 = try copyFixture(named: "GH010001.MP4")
        let chunk2 = try copyFixture(named: "GH020001.MP4")
        let chunk3 = try copyFixture(named: "GH030001.MP4")

        try ChunkStitcher.stitch(chunks: [chunk1, chunk2, chunk3])

        let contents = try FileManager.default.contentsOfDirectory(atPath: tempDir.path)
        let mp4s = contents.filter { $0.hasSuffix(".MP4") }
        XCTAssertEqual(mp4s.count, 1, "Only the stitched output file should remain")
    }

    func testStitch_progressCallbackFired() throws {
        let chunk1 = try copyFixture(named: "GH010001.MP4")
        let chunk2 = try copyFixture(named: "GH020001.MP4")

        var calls: [(Int, Int)] = []
        try ChunkStitcher.stitch(chunks: [chunk1, chunk2]) { completed, total in
            calls.append((completed, total))
        }

        // All chunks deleted (2 total), so progress fires twice
        XCTAssertEqual(calls.count, 2)
        XCTAssertEqual(calls[0].0, 1)
        XCTAssertEqual(calls[1].0, 2)
        XCTAssertEqual(calls[0].1, 2)
    }

    // MARK: - Error cases

    func testStitch_emptyArray_throwsEmpty() {
        XCTAssertThrowsError(try ChunkStitcher.stitch(chunks: [])) { error in
            guard let stitchError = error as? ChunkStitcherError else {
                XCTFail("Expected ChunkStitcherError, got \(error)")
                return
            }
            if case .empty = stitchError { } else {
                XCTFail("Expected .empty, got \(stitchError)")
            }
        }
    }

    func testStitch_singleChunk_throwsEmpty() throws {
        let chunk1 = try copyFixture(named: "GH010001.MP4")

        XCTAssertThrowsError(try ChunkStitcher.stitch(chunks: [chunk1])) { error in
            guard let stitchError = error as? ChunkStitcherError else {
                XCTFail("Expected ChunkStitcherError, got \(error)")
                return
            }
            if case .empty = stitchError { } else {
                XCTFail("Expected .empty, got \(stitchError)")
            }
        }
    }

    func testStitch_destinationNotFound_throws() throws {
        let missing = tempDir.appendingPathComponent("missing.MP4")
        let chunk2 = try copyFixture(named: "GH020001.MP4")

        XCTAssertThrowsError(try ChunkStitcher.stitch(chunks: [missing, chunk2])) { error in
            guard let stitchError = error as? ChunkStitcherError else {
                XCTFail("Expected ChunkStitcherError, got \(error)")
                return
            }
            if case .destinationNotFound = stitchError { } else {
                XCTFail("Expected .destinationNotFound, got \(stitchError)")
            }
        }
    }

    func testStitch_sourceNotFound_throws() throws {
        let chunk1 = try copyFixture(named: "GH010001.MP4")
        let missing = tempDir.appendingPathComponent("missing.MP4")

        XCTAssertThrowsError(try ChunkStitcher.stitch(chunks: [chunk1, missing])) { error in
            guard let stitchError = error as? ChunkStitcherError else {
                XCTFail("Expected ChunkStitcherError, got \(error)")
                return
            }
            if case .sourceNotFound(let url) = stitchError {
                XCTAssertEqual(url, missing)
            } else {
                XCTFail("Expected .sourceNotFound, got \(stitchError)")
            }
        }
    }
}
