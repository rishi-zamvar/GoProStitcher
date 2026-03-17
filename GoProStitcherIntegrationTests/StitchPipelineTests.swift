import XCTest
import GoProStitcherKit

final class StitchPipelineTests: XCTestCase {
    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = try? TempDirectoryHelper.create()
        XCTAssertNotNil(tempDir)
    }

    override func tearDown() {
        if let dir = tempDir { TempDirectoryHelper.cleanup(url: dir) }
        super.tearDown()
    }

    func testFullStitchAndArchivePipeline() throws {
        // Create 3 chunks with known distinct byte patterns
        let chunk1URL = tempDir.appendingPathComponent("GH010001.MP4")
        let chunk2URL = tempDir.appendingPathComponent("GH020001.MP4")
        let chunk3URL = tempDir.appendingPathComponent("GH030001.MP4")
        try Data(repeating: 0xAA, count: 100).write(to: chunk1URL)
        try Data(repeating: 0xBB, count: 200).write(to: chunk2URL)
        try Data(repeating: 0xCC, count: 300).write(to: chunk3URL)

        let archiveDir = tempDir.appendingPathComponent("archive")

        // Step 1: Archive all chunks first (preserves originals)
        try ChunkArchiver.archive(chunks: [chunk1URL, chunk2URL, chunk3URL], into: archiveDir)

        // Verify zip files exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: archiveDir.appendingPathComponent("GH010001.MP4.zip").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: archiveDir.appendingPathComponent("GH020001.MP4.zip").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: archiveDir.appendingPathComponent("GH030001.MP4.zip").path))

        // Step 2: Stitch (appends chunk2 and chunk3 onto chunk1, removes chunk2 and chunk3)
        try ChunkStitcher.stitch(chunks: [chunk1URL, chunk2URL, chunk3URL])

        // Verify stitched file = 600 bytes (100 + 200 + 300)
        let attrs = try FileManager.default.attributesOfItem(atPath: chunk1URL.path)
        let size = attrs[.size] as? Int ?? 0
        XCTAssertEqual(size, 600, "Stitched file should be sum of all chunk sizes")

        // Verify chunk2 and chunk3 were removed from disk (not duplicated)
        XCTAssertFalse(FileManager.default.fileExists(atPath: chunk2URL.path), "Source chunk2 should be removed after stitch")
        XCTAssertFalse(FileManager.default.fileExists(atPath: chunk3URL.path), "Source chunk3 should be removed after stitch")

        // Verify byte content is correct concatenation
        let stitchedData = try Data(contentsOf: chunk1URL)
        XCTAssertEqual(stitchedData[0], 0xAA)       // first byte of chunk1
        XCTAssertEqual(stitchedData[99], 0xAA)      // last byte of chunk1
        XCTAssertEqual(stitchedData[100], 0xBB)     // first byte of chunk2
        XCTAssertEqual(stitchedData[299], 0xBB)     // last byte of chunk2
        XCTAssertEqual(stitchedData[300], 0xCC)     // first byte of chunk3
        XCTAssertEqual(stitchedData[599], 0xCC)     // last byte of chunk3
    }

    func testStitchErrorOnMissingDestination() throws {
        let missing = tempDir.appendingPathComponent("MISSING.MP4")
        let chunk2URL = tempDir.appendingPathComponent("GH020001.MP4")
        try Data(repeating: 0xBB, count: 50).write(to: chunk2URL)
        XCTAssertThrowsError(try ChunkStitcher.stitch(chunks: [missing, chunk2URL])) { error in
            if case ChunkStitcherError.destinationNotFound = error { } else {
                XCTFail("Expected .destinationNotFound, got \(error)")
            }
        }
    }

    func testArchiveProgressCallbackCount() throws {
        let urls = try GoProFileFactory.makeSequence(in: tempDir, count: 4, chunkSizeBytes: 50)
        let archiveDir = tempDir.appendingPathComponent("archive")
        var callbackIndices: [Int] = []
        try ChunkArchiver.archive(chunks: urls, into: archiveDir) { idx, total in
            callbackIndices.append(idx)
        }
        // ChunkArchiver fires progress?(index + 1, total), so indices are 1-based: [1, 2, 3, 4]
        XCTAssertEqual(callbackIndices, [1, 2, 3, 4], "Progress callback should fire once per chunk with 1-based index")
    }
}
