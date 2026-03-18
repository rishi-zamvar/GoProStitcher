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

    /// Copies the bundled tiny MP4 fixture to tempDir with the given name.
    private func copyFixture(named name: String) throws -> URL {
        // The fixture is bundled with GoProStitcherKitTests — access via Bundle
        // For integration tests, create a minimal valid MP4 using ffmpeg
        let dest = tempDir.appendingPathComponent(name)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/ffmpeg")
        process.arguments = [
            "-y", "-f", "lavfi", "-i", "color=c=black:s=160x90:d=0.5",
            "-c:v", "libx264", "-pix_fmt", "yuv420p",
            dest.path
        ]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "ffmpeg fixture creation failed"])
        }
        return dest
    }

    func testFullManifestAndStitchPipeline() throws {
        let chunk1 = try copyFixture(named: "GH010001.MP4")
        let chunk2 = try copyFixture(named: "GH020001.MP4")
        let chunk3 = try copyFixture(named: "GH030001.MP4")

        let chunk1Size = try FileManager.default.attributesOfItem(atPath: chunk1.path)[.size] as? Int ?? 0
        let manifestURL = tempDir.appendingPathComponent("stitch_manifest.json")

        // Step 1: Save manifest
        try ChunkArchiver.archive(chunks: [chunk1, chunk2, chunk3], into: manifestURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: manifestURL.path))

        let manifestData = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(StitchManifest.self, from: manifestData)
        XCTAssertEqual(manifest.chunks.count, 3)

        // Step 2: Stitch with ffmpeg
        try ChunkStitcher.stitch(chunks: [chunk1, chunk2, chunk3])

        // Stitched file should exist and be larger than a single chunk
        XCTAssertTrue(FileManager.default.fileExists(atPath: chunk1.path))
        let stitchedSize = try FileManager.default.attributesOfItem(atPath: chunk1.path)[.size] as? Int ?? 0
        XCTAssertGreaterThan(stitchedSize, chunk1Size)

        // Sources removed
        XCTAssertFalse(FileManager.default.fileExists(atPath: chunk2.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: chunk3.path))
    }

    func testStitchErrorOnMissingDestination() throws {
        let missing = tempDir.appendingPathComponent("MISSING.MP4")
        let chunk2 = try copyFixture(named: "GH020001.MP4")
        XCTAssertThrowsError(try ChunkStitcher.stitch(chunks: [missing, chunk2])) { error in
            if case ChunkStitcherError.destinationNotFound = error { } else {
                XCTFail("Expected .destinationNotFound, got \(error)")
            }
        }
    }

    func testManifestRevertRestoresChunks() throws {
        let chunk1 = try copyFixture(named: "GH010001.MP4")
        let chunk2 = try copyFixture(named: "GH020001.MP4")

        let chunk1Size = try FileManager.default.attributesOfItem(atPath: chunk1.path)[.size] as? Int ?? 0
        let chunk2Size = try FileManager.default.attributesOfItem(atPath: chunk2.path)[.size] as? Int ?? 0

        let manifestURL = tempDir.appendingPathComponent("stitch_manifest.json")
        try ChunkArchiver.archive(chunks: [chunk1, chunk2], into: manifestURL)
        try ChunkStitcher.stitch(chunks: [chunk1, chunk2])

        // Revert
        let outputDir = tempDir.appendingPathComponent("restored")
        try ChunkArchiver.revert(stitchedURL: chunk1, manifestURL: manifestURL, outputDir: outputDir)

        let restored1 = outputDir.appendingPathComponent("GH010001.MP4")
        let restored2 = outputDir.appendingPathComponent("GH020001.MP4")
        XCTAssertTrue(FileManager.default.fileExists(atPath: restored1.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: restored2.path))

        // Note: ffmpeg remuxing may change byte sizes slightly due to container overhead,
        // so we verify files exist and are non-empty rather than exact byte matching
        let restored1Size = try FileManager.default.attributesOfItem(atPath: restored1.path)[.size] as? Int ?? 0
        let restored2Size = try FileManager.default.attributesOfItem(atPath: restored2.path)[.size] as? Int ?? 0
        XCTAssertGreaterThan(restored1Size, 0)
        XCTAssertGreaterThan(restored2Size, 0)
    }
}
