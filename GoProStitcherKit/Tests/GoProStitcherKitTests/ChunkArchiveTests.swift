import XCTest
@testable import GoProStitcherKit

final class ChunkArchiveTests: XCTestCase {
    private var tempDir: URL!
    private var archiveDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = try? TempDirectoryHelper.create()
        XCTAssertNotNil(tempDir, "Failed to create temp directory in setUp")
        archiveDir = tempDir?.appendingPathComponent("archive", isDirectory: true)
    }

    override func tearDown() {
        TempDirectoryHelper.cleanup(url: tempDir)
        tempDir = nil
        archiveDir = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeFile(at url: URL, byte: UInt8, count: Int) throws {
        let data = Data(repeating: byte, count: count)
        try data.write(to: url)
    }

    // MARK: - Archive creation

    func testArchive_threeChunks_createsIndividualZips() throws {
        let chunk1 = tempDir.appendingPathComponent("GH010001.MP4")
        let chunk2 = tempDir.appendingPathComponent("GH020001.MP4")
        let chunk3 = tempDir.appendingPathComponent("GH030001.MP4")

        try makeFile(at: chunk1, byte: 0xAA, count: 100)
        try makeFile(at: chunk2, byte: 0xBB, count: 200)
        try makeFile(at: chunk3, byte: 0xCC, count: 300)

        try ChunkArchiver.archive(chunks: [chunk1, chunk2, chunk3], into: archiveDir)

        // archiveDir should exist and contain 3 zip files
        XCTAssertTrue(FileManager.default.fileExists(atPath: archiveDir.path), "Archive directory should be created")

        let zip1 = archiveDir.appendingPathComponent("GH010001.MP4.zip")
        let zip2 = archiveDir.appendingPathComponent("GH020001.MP4.zip")
        let zip3 = archiveDir.appendingPathComponent("GH030001.MP4.zip")

        XCTAssertTrue(FileManager.default.fileExists(atPath: zip1.path), "GH010001.MP4.zip should exist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: zip2.path), "GH020001.MP4.zip should exist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: zip3.path), "GH030001.MP4.zip should exist")
    }

    func testArchive_zipFilesHaveCorrectNames() throws {
        let chunk1 = tempDir.appendingPathComponent("chunk_A.mp4")
        let chunk2 = tempDir.appendingPathComponent("chunk_B.mp4")

        try makeFile(at: chunk1, byte: 0xAA, count: 50)
        try makeFile(at: chunk2, byte: 0xBB, count: 50)

        try ChunkArchiver.archive(chunks: [chunk1, chunk2], into: archiveDir)

        let zipA = archiveDir.appendingPathComponent("chunk_A.mp4.zip")
        let zipB = archiveDir.appendingPathComponent("chunk_B.mp4.zip")

        XCTAssertTrue(FileManager.default.fileExists(atPath: zipA.path), "chunk_A.mp4.zip should exist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: zipB.path), "chunk_B.mp4.zip should exist")
    }

    func testArchive_progressCallbackCalled() throws {
        let chunk1 = tempDir.appendingPathComponent("chunk1.mp4")
        let chunk2 = tempDir.appendingPathComponent("chunk2.mp4")
        let chunk3 = tempDir.appendingPathComponent("chunk3.mp4")

        try makeFile(at: chunk1, byte: 0xAA, count: 50)
        try makeFile(at: chunk2, byte: 0xBB, count: 50)
        try makeFile(at: chunk3, byte: 0xCC, count: 50)

        var progressCalls: [(current: Int, total: Int)] = []
        try ChunkArchiver.archive(chunks: [chunk1, chunk2, chunk3], into: archiveDir) { current, total in
            progressCalls.append((current, total))
        }

        XCTAssertEqual(progressCalls.count, 3, "Progress callback should be called once per chunk")
        XCTAssertEqual(progressCalls[0].total, 3, "Total should always be 3")
        XCTAssertEqual(progressCalls[0].current, 1, "First callback: current=1")
        XCTAssertEqual(progressCalls[1].current, 2, "Second callback: current=2")
        XCTAssertEqual(progressCalls[2].current, 3, "Third callback: current=3")
    }

    func testArchive_progressCallbackIsNilByDefault() throws {
        let chunk1 = tempDir.appendingPathComponent("chunk1.mp4")
        try makeFile(at: chunk1, byte: 0xAA, count: 50)
        let chunk2 = tempDir.appendingPathComponent("chunk2.mp4")
        try makeFile(at: chunk2, byte: 0xBB, count: 50)

        // Should not throw when progress is nil (the default)
        XCTAssertNoThrow(try ChunkArchiver.archive(chunks: [chunk1, chunk2], into: archiveDir))
    }

    // MARK: - Error cases

    func testArchive_missingSource_throwsSourceNotFound() throws {
        let missing = tempDir.appendingPathComponent("nonexistent.mp4")

        XCTAssertThrowsError(try ChunkArchiver.archive(chunks: [missing], into: archiveDir)) { error in
            guard let archiveError = error as? ChunkArchiverError else {
                XCTFail("Expected ChunkArchiverError, got \(error)")
                return
            }
            if case .sourceNotFound(let url) = archiveError {
                XCTAssertEqual(url, missing, "Error should reference the missing source URL")
            } else {
                XCTFail("Expected .sourceNotFound, got \(archiveError)")
            }
        }
    }
}
