import XCTest
@testable import GoProStitcherKit

final class ChunkArchiveTests: XCTestCase {
    private var tempDir: URL!
    private var manifestURL: URL!

    override func setUp() {
        super.setUp()
        tempDir = try? TempDirectoryHelper.create()
        XCTAssertNotNil(tempDir, "Failed to create temp directory in setUp")
        manifestURL = tempDir?.appendingPathComponent("stitch_manifest.json")
    }

    override func tearDown() {
        TempDirectoryHelper.cleanup(url: tempDir)
        tempDir = nil
        manifestURL = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeFile(at url: URL, byte: UInt8, count: Int) throws {
        let data = Data(repeating: byte, count: count)
        try data.write(to: url)
    }

    // MARK: - Manifest creation

    func testArchive_threeChunks_createsManifest() throws {
        let chunk1 = tempDir.appendingPathComponent("GH010001.MP4")
        let chunk2 = tempDir.appendingPathComponent("GH020001.MP4")
        let chunk3 = tempDir.appendingPathComponent("GH030001.MP4")

        try makeFile(at: chunk1, byte: 0xAA, count: 100)
        try makeFile(at: chunk2, byte: 0xBB, count: 200)
        try makeFile(at: chunk3, byte: 0xCC, count: 300)

        try ChunkArchiver.archive(chunks: [chunk1, chunk2, chunk3], into: manifestURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: manifestURL.path), "Manifest file should exist")

        let data = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(StitchManifest.self, from: data)

        XCTAssertEqual(manifest.version, 1)
        XCTAssertEqual(manifest.stitchedFilename, "GH010001.MP4")
        XCTAssertEqual(manifest.chunks.count, 3)
        XCTAssertEqual(manifest.chunks[0].filename, "GH010001.MP4")
        XCTAssertEqual(manifest.chunks[0].sizeBytes, 100)
        XCTAssertEqual(manifest.chunks[1].filename, "GH020001.MP4")
        XCTAssertEqual(manifest.chunks[1].sizeBytes, 200)
        XCTAssertEqual(manifest.chunks[2].filename, "GH030001.MP4")
        XCTAssertEqual(manifest.chunks[2].sizeBytes, 300)
    }

    func testArchive_progressCallbackCalled() throws {
        let chunk1 = tempDir.appendingPathComponent("chunk1.mp4")
        let chunk2 = tempDir.appendingPathComponent("chunk2.mp4")
        let chunk3 = tempDir.appendingPathComponent("chunk3.mp4")

        try makeFile(at: chunk1, byte: 0xAA, count: 50)
        try makeFile(at: chunk2, byte: 0xBB, count: 50)
        try makeFile(at: chunk3, byte: 0xCC, count: 50)

        var progressCalls: [(current: Int, total: Int)] = []
        try ChunkArchiver.archive(chunks: [chunk1, chunk2, chunk3], into: manifestURL) { current, total in
            progressCalls.append((current, total))
        }

        XCTAssertEqual(progressCalls.count, 3, "Progress callback should be called once per chunk")
        XCTAssertEqual(progressCalls[0].total, 3)
        XCTAssertEqual(progressCalls[0].current, 1)
        XCTAssertEqual(progressCalls[1].current, 2)
        XCTAssertEqual(progressCalls[2].current, 3)
    }

    func testArchive_progressCallbackIsNilByDefault() throws {
        let chunk1 = tempDir.appendingPathComponent("chunk1.mp4")
        try makeFile(at: chunk1, byte: 0xAA, count: 50)

        XCTAssertNoThrow(try ChunkArchiver.archive(chunks: [chunk1], into: manifestURL))
    }

    // MARK: - Error cases

    func testArchive_missingSource_throwsSourceNotFound() throws {
        let missing = tempDir.appendingPathComponent("nonexistent.mp4")

        XCTAssertThrowsError(try ChunkArchiver.archive(chunks: [missing], into: manifestURL)) { error in
            guard let archiveError = error as? ChunkArchiverError else {
                XCTFail("Expected ChunkArchiverError, got \(error)")
                return
            }
            if case .sourceNotFound(let url) = archiveError {
                XCTAssertEqual(url, missing)
            } else {
                XCTFail("Expected .sourceNotFound, got \(archiveError)")
            }
        }
    }

    // MARK: - Revert

    func testRevert_splitsStitchedFileBackIntoChunks() throws {
        let chunk1 = tempDir.appendingPathComponent("GH010001.MP4")
        let chunk2 = tempDir.appendingPathComponent("GH020001.MP4")
        let chunk3 = tempDir.appendingPathComponent("GH030001.MP4")

        try makeFile(at: chunk1, byte: 0xAA, count: 100)
        try makeFile(at: chunk2, byte: 0xBB, count: 200)
        try makeFile(at: chunk3, byte: 0xCC, count: 300)

        // Save manifest
        try ChunkArchiver.archive(chunks: [chunk1, chunk2, chunk3], into: manifestURL)

        // Simulate stitching: concatenate all into chunk1
        let stitchedData = Data(repeating: 0xAA, count: 100)
            + Data(repeating: 0xBB, count: 200)
            + Data(repeating: 0xCC, count: 300)
        try stitchedData.write(to: chunk1)

        // Revert into a separate output directory
        let outputDir = tempDir.appendingPathComponent("restored")
        try ChunkArchiver.revert(stitchedURL: chunk1, manifestURL: manifestURL, outputDir: outputDir)

        // Verify restored chunks
        let restored1 = try Data(contentsOf: outputDir.appendingPathComponent("GH010001.MP4"))
        let restored2 = try Data(contentsOf: outputDir.appendingPathComponent("GH020001.MP4"))
        let restored3 = try Data(contentsOf: outputDir.appendingPathComponent("GH030001.MP4"))

        XCTAssertEqual(restored1.count, 100)
        XCTAssertEqual(restored2.count, 200)
        XCTAssertEqual(restored3.count, 300)
        XCTAssertEqual(restored1[0], 0xAA)
        XCTAssertEqual(restored2[0], 0xBB)
        XCTAssertEqual(restored3[0], 0xCC)
    }
}
