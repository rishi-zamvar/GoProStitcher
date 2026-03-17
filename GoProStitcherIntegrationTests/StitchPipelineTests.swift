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

    func testFullManifestAndStitchPipeline() throws {
        // Create 3 chunks with known distinct byte patterns
        let chunk1URL = tempDir.appendingPathComponent("GH010001.MP4")
        let chunk2URL = tempDir.appendingPathComponent("GH020001.MP4")
        let chunk3URL = tempDir.appendingPathComponent("GH030001.MP4")
        try Data(repeating: 0xAA, count: 100).write(to: chunk1URL)
        try Data(repeating: 0xBB, count: 200).write(to: chunk2URL)
        try Data(repeating: 0xCC, count: 300).write(to: chunk3URL)

        let manifestURL = tempDir.appendingPathComponent("stitch_manifest.json")

        // Step 1: Save manifest (records chunk boundaries for reversion)
        try ChunkArchiver.archive(chunks: [chunk1URL, chunk2URL, chunk3URL], into: manifestURL)

        // Verify manifest exists and is correct
        XCTAssertTrue(FileManager.default.fileExists(atPath: manifestURL.path))
        let manifestData = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(StitchManifest.self, from: manifestData)
        XCTAssertEqual(manifest.chunks.count, 3)
        XCTAssertEqual(manifest.chunks[0].sizeBytes, 100)
        XCTAssertEqual(manifest.chunks[1].sizeBytes, 200)
        XCTAssertEqual(manifest.chunks[2].sizeBytes, 300)

        // Step 2: Stitch (appends chunk2 and chunk3 onto chunk1, removes chunk2 and chunk3)
        try ChunkStitcher.stitch(chunks: [chunk1URL, chunk2URL, chunk3URL])

        // Verify stitched file = 600 bytes (100 + 200 + 300)
        let attrs = try FileManager.default.attributesOfItem(atPath: chunk1URL.path)
        let size = attrs[.size] as? Int ?? 0
        XCTAssertEqual(size, 600, "Stitched file should be sum of all chunk sizes")

        // Verify chunk2 and chunk3 were removed from disk (not duplicated)
        XCTAssertFalse(FileManager.default.fileExists(atPath: chunk2URL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: chunk3URL.path))

        // Verify byte content is correct concatenation
        let stitchedData = try Data(contentsOf: chunk1URL)
        XCTAssertEqual(stitchedData[0], 0xAA)
        XCTAssertEqual(stitchedData[100], 0xBB)
        XCTAssertEqual(stitchedData[300], 0xCC)
    }

    func testRevertRestoresOriginalChunks() throws {
        let chunk1URL = tempDir.appendingPathComponent("GH010001.MP4")
        let chunk2URL = tempDir.appendingPathComponent("GH020001.MP4")
        try Data(repeating: 0xAA, count: 100).write(to: chunk1URL)
        try Data(repeating: 0xBB, count: 200).write(to: chunk2URL)

        let manifestURL = tempDir.appendingPathComponent("stitch_manifest.json")
        try ChunkArchiver.archive(chunks: [chunk1URL, chunk2URL], into: manifestURL)
        try ChunkStitcher.stitch(chunks: [chunk1URL, chunk2URL])

        // Revert
        let outputDir = tempDir.appendingPathComponent("restored")
        try ChunkArchiver.revert(stitchedURL: chunk1URL, manifestURL: manifestURL, outputDir: outputDir)

        let restored1 = try Data(contentsOf: outputDir.appendingPathComponent("GH010001.MP4"))
        let restored2 = try Data(contentsOf: outputDir.appendingPathComponent("GH020001.MP4"))
        XCTAssertEqual(restored1.count, 100)
        XCTAssertEqual(restored2.count, 200)
        XCTAssertEqual(restored1[0], 0xAA)
        XCTAssertEqual(restored2[0], 0xBB)
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
}
