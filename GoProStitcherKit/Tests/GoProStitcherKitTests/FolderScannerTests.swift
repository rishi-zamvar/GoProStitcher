import XCTest
@testable import GoProStitcherKit

final class FolderScannerTests: XCTestCase {

    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = try? TempDirectoryHelper.create()
        XCTAssertNotNil(tempDir, "Failed to create temp directory")
    }

    override func tearDown() {
        if let tempDir = tempDir {
            TempDirectoryHelper.cleanup(url: tempDir)
        }
        super.tearDown()
    }

    // MARK: - Empty folder

    func testScan_emptyFolder() {
        let result = FolderScanner.scan(url: tempDir)
        if case .empty = result {
            // expected
        } else {
            XCTFail("Expected .empty but got \(result)")
        }
    }

    // MARK: - Non-GoPro MP4 files

    func testScan_noGoProFiles() {
        let fileURL = tempDir.appendingPathComponent("random.MP4")
        let data = Data(count: 512)
        try? data.write(to: fileURL)

        let result = FolderScanner.scan(url: tempDir)
        if case .noGoProFiles = result {
            // expected
        } else {
            XCTFail("Expected .noGoProFiles but got \(result)")
        }
    }

    // MARK: - Non-MP4 files only

    func testScan_nonMP4Files() {
        let fileURL = tempDir.appendingPathComponent("notes.txt")
        let data = Data("some text".utf8)
        try? data.write(to: fileURL)

        let result = FolderScanner.scan(url: tempDir)
        if case .empty = result {
            // expected: no MP4s found, treated as empty
        } else {
            XCTFail("Expected .empty but got \(result)")
        }
    }

    // MARK: - Single GoPro chunk

    func testScan_singleChunk() throws {
        try GoProFileFactory.makeChunk(in: tempDir, chapter: 1, fileNumber: 1)

        let result = FolderScanner.scan(url: tempDir)
        guard case .success(let chunks) = result else {
            XCTFail("Expected .success but got \(result)")
            return
        }
        XCTAssertEqual(chunks.count, 1)
    }

    // MARK: - Sequence sorted by chapter

    func testScan_sequenceSorted() throws {
        try GoProFileFactory.makeSequence(in: tempDir, count: 3)

        let result = FolderScanner.scan(url: tempDir)
        guard case .success(let chunks) = result else {
            XCTFail("Expected .success but got \(result)")
            return
        }
        XCTAssertEqual(chunks.count, 3)
        XCTAssertEqual(chunks[0].chunk.chapter, 1)
        XCTAssertEqual(chunks[1].chunk.chapter, 2)
        XCTAssertEqual(chunks[2].chunk.chapter, 3)
    }

    // MARK: - Ignores non-GoPro alongside GoPro files

    func testScan_ignoresNonGoPro() throws {
        try GoProFileFactory.makeSequence(in: tempDir, count: 2)
        let randomURL = tempDir.appendingPathComponent("random.MP4")
        try Data(count: 256).write(to: randomURL)

        let result = FolderScanner.scan(url: tempDir)
        guard case .success(let chunks) = result else {
            XCTFail("Expected .success but got \(result)")
            return
        }
        XCTAssertEqual(chunks.count, 2, "Should have exactly 2 GoPro chunks, ignoring random.MP4")
    }

    // MARK: - Mixed GH and GX prefixes

    func testScan_mixedPrefixes() throws {
        try GoProFileFactory.makeChunk(in: tempDir, chapter: 1, fileNumber: 1, prefix: "GH")
        try GoProFileFactory.makeChunk(in: tempDir, chapter: 1, fileNumber: 2, prefix: "GX")

        let result = FolderScanner.scan(url: tempDir)
        guard case .success(let chunks) = result else {
            XCTFail("Expected .success but got \(result)")
            return
        }
        XCTAssertEqual(chunks.count, 2, "Should include both GH and GX prefixes")
        let prefixes = Set(chunks.map { $0.chunk.prefix })
        XCTAssertTrue(prefixes.contains("GH"))
        XCTAssertTrue(prefixes.contains("GX"))
    }

    // MARK: - Total size

    func testScan_totalSize() throws {
        try GoProFileFactory.makeSequence(in: tempDir, count: 3, chunkSizeBytes: 2048)

        let result = FolderScanner.scan(url: tempDir)
        guard case .success(let chunks) = result else {
            XCTFail("Expected .success but got \(result)")
            return
        }
        let totalSize = chunks.reduce(0) { $0 + $1.sizeBytes }
        XCTAssertEqual(totalSize, 6144, "3 chunks * 2048 bytes = 6144")
    }

    // MARK: - Chunk URL exists on disk

    func testScan_chunkURLExists() throws {
        try GoProFileFactory.makeChunk(in: tempDir, chapter: 1, fileNumber: 1)

        let result = FolderScanner.scan(url: tempDir)
        guard case .success(let chunks) = result else {
            XCTFail("Expected .success but got \(result)")
            return
        }
        XCTAssertEqual(chunks.count, 1)
        let chunkURL = chunks[0].url
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: chunkURL.path),
            "Chunk URL should point to an existing file on disk"
        )
    }
}
