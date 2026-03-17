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

    /// Creates a file at `url` filled with `count` repetitions of `byte`.
    private func makeFile(at url: URL, byte: UInt8, count: Int) throws {
        let data = Data(repeating: byte, count: count)
        try data.write(to: url)
    }

    // MARK: - Binary concatenation

    func testStitch_threeConcatenationProducesCorrectBytes() throws {
        let chunk1 = tempDir.appendingPathComponent("chunk1.mp4")
        let chunk2 = tempDir.appendingPathComponent("chunk2.mp4")
        let chunk3 = tempDir.appendingPathComponent("chunk3.mp4")

        try makeFile(at: chunk1, byte: 0xAA, count: 100)
        try makeFile(at: chunk2, byte: 0xBB, count: 200)
        try makeFile(at: chunk3, byte: 0xCC, count: 300)

        try ChunkStitcher.stitch(chunks: [chunk1, chunk2, chunk3])

        // chunk1 should now contain all three in order
        let result = try Data(contentsOf: chunk1)
        XCTAssertEqual(result.count, 600, "Stitched file should be 600 bytes")

        let expectedFirst = Data(repeating: 0xAA, count: 100)
        let expectedSecond = Data(repeating: 0xBB, count: 200)
        let expectedThird = Data(repeating: 0xCC, count: 300)

        XCTAssertEqual(result[0..<100], expectedFirst, "First 100 bytes should be 0xAA")
        XCTAssertEqual(result[100..<300], expectedSecond, "Next 200 bytes should be 0xBB")
        XCTAssertEqual(result[300..<600], expectedThird, "Last 300 bytes should be 0xCC")
    }

    func testStitch_appendsInPlace_noNewFilesAtSourceLevel() throws {
        let chunk1 = tempDir.appendingPathComponent("chunk1.mp4")
        let chunk2 = tempDir.appendingPathComponent("chunk2.mp4")
        let chunk3 = tempDir.appendingPathComponent("chunk3.mp4")

        try makeFile(at: chunk1, byte: 0xAA, count: 50)
        try makeFile(at: chunk2, byte: 0xBB, count: 50)
        try makeFile(at: chunk3, byte: 0xCC, count: 50)

        try ChunkStitcher.stitch(chunks: [chunk1, chunk2, chunk3])

        let contents = try FileManager.default.contentsOfDirectory(atPath: tempDir.path)
        // Only chunk1 should remain; chunk2 and chunk3 removed after append
        XCTAssertEqual(contents.count, 1, "Only the destination file should remain")
        XCTAssertTrue(FileManager.default.fileExists(atPath: chunk1.path), "chunk1 should exist in-place")
    }

    func testStitch_sourcesRemovedAfterAppend() throws {
        let chunk1 = tempDir.appendingPathComponent("chunk1.mp4")
        let chunk2 = tempDir.appendingPathComponent("chunk2.mp4")

        try makeFile(at: chunk1, byte: 0xAA, count: 100)
        try makeFile(at: chunk2, byte: 0xBB, count: 100)

        try ChunkStitcher.stitch(chunks: [chunk1, chunk2])

        XCTAssertFalse(FileManager.default.fileExists(atPath: chunk2.path), "Source chunk2 should be removed after append")
        XCTAssertTrue(FileManager.default.fileExists(atPath: chunk1.path), "Destination chunk1 should still exist")
    }

    // MARK: - Error cases

    func testStitch_emptyArray_throwsEmpty() {
        XCTAssertThrowsError(try ChunkStitcher.stitch(chunks: [])) { error in
            guard let stitchError = error as? ChunkStitcherError else {
                XCTFail("Expected ChunkStitcherError, got \(error)")
                return
            }
            if case .empty = stitchError {
                // expected
            } else {
                XCTFail("Expected .empty, got \(stitchError)")
            }
        }
    }

    func testStitch_singleChunk_throwsEmpty() throws {
        let chunk1 = tempDir.appendingPathComponent("chunk1.mp4")
        try makeFile(at: chunk1, byte: 0xAA, count: 100)

        XCTAssertThrowsError(try ChunkStitcher.stitch(chunks: [chunk1])) { error in
            guard let stitchError = error as? ChunkStitcherError else {
                XCTFail("Expected ChunkStitcherError, got \(error)")
                return
            }
            if case .empty = stitchError {
                // expected
            } else {
                XCTFail("Expected .empty, got \(stitchError)")
            }
        }
    }

    func testStitch_destinationNotFound_throws() throws {
        let missing = tempDir.appendingPathComponent("missing_destination.mp4")
        let chunk2 = tempDir.appendingPathComponent("chunk2.mp4")
        try makeFile(at: chunk2, byte: 0xBB, count: 100)

        XCTAssertThrowsError(try ChunkStitcher.stitch(chunks: [missing, chunk2])) { error in
            guard let stitchError = error as? ChunkStitcherError else {
                XCTFail("Expected ChunkStitcherError, got \(error)")
                return
            }
            if case .destinationNotFound = stitchError {
                // expected
            } else {
                XCTFail("Expected .destinationNotFound, got \(stitchError)")
            }
        }
    }

    func testStitch_sourceNotFound_throws() throws {
        let chunk1 = tempDir.appendingPathComponent("chunk1.mp4")
        let missing = tempDir.appendingPathComponent("missing_source.mp4")
        try makeFile(at: chunk1, byte: 0xAA, count: 100)

        XCTAssertThrowsError(try ChunkStitcher.stitch(chunks: [chunk1, missing])) { error in
            guard let stitchError = error as? ChunkStitcherError else {
                XCTFail("Expected ChunkStitcherError, got \(error)")
                return
            }
            if case .sourceNotFound(let url) = stitchError {
                XCTAssertEqual(url, missing, "Error should reference the missing source URL")
            } else {
                XCTFail("Expected .sourceNotFound, got \(stitchError)")
            }
        }
    }
}
