import XCTest
@testable import GoProStitcherKit

final class TestHelpersTests: XCTestCase {
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

    // MARK: - TempDirectoryHelper tests

    func testTempDirectoryCreateAndCleanup() throws {
        let dir = try TempDirectoryHelper.create()
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.path), "Directory should exist after create()")
        TempDirectoryHelper.cleanup(url: dir)
        XCTAssertFalse(FileManager.default.fileExists(atPath: dir.path), "Directory should not exist after cleanup(url:)")
    }

    // MARK: - GoProFileFactory tests

    func testMakeChunkCreatesCorrectFilename() throws {
        let url = try GoProFileFactory.makeChunk(in: tempDir, chapter: 1, fileNumber: 1, prefix: "GH")
        XCTAssertEqual(url.lastPathComponent, "GH010001.MP4")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testMakeChunkCreatesCorrectFilenameGX() throws {
        let url = try GoProFileFactory.makeChunk(in: tempDir, chapter: 1, fileNumber: 1, prefix: "GX")
        XCTAssertEqual(url.lastPathComponent, "GX010001.MP4")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testMakeChunkHasCorrectSize() throws {
        let url = try GoProFileFactory.makeChunk(in: tempDir, chapter: 1, fileNumber: 1, sizeBytes: 512)
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int
        XCTAssertEqual(fileSize, 512, "File size should be exactly 512 bytes")
    }

    func testMakeSequenceOrder() throws {
        let urls = try GoProFileFactory.makeSequence(in: tempDir, count: 3)
        XCTAssertEqual(urls.count, 3)
        XCTAssertEqual(urls[0].lastPathComponent, "GH010001.MP4")
        XCTAssertEqual(urls[1].lastPathComponent, "GH020001.MP4")
        XCTAssertEqual(urls[2].lastPathComponent, "GH030001.MP4")
    }

    func testGoProNameFormatter() {
        let name = GoProFileFactory.goProName(prefix: "GH", chapter: 2, fileNumber: 15)
        XCTAssertEqual(name, "GH020015.MP4")
    }
}
