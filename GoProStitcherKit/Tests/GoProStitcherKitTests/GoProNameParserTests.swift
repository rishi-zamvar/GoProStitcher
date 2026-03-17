import XCTest
@testable import GoProStitcherKit

final class GoProNameParserTests: XCTestCase {

    // MARK: - Parse GH prefix

    func testParseGH_basic() {
        let chunk = GoProNameParser.parse("GH010001.MP4")
        XCTAssertNotNil(chunk)
        XCTAssertEqual(chunk?.prefix, "GH")
        XCTAssertEqual(chunk?.chapter, 1)
        XCTAssertEqual(chunk?.fileNumber, 1)
    }

    func testParseGH_chapter5() {
        let chunk = GoProNameParser.parse("GH050023.MP4")
        XCTAssertNotNil(chunk)
        XCTAssertEqual(chunk?.prefix, "GH")
        XCTAssertEqual(chunk?.chapter, 5)
        XCTAssertEqual(chunk?.fileNumber, 23)
    }

    func testParseGH_maxValues() {
        let chunk = GoProNameParser.parse("GH991234.MP4")
        XCTAssertNotNil(chunk)
        XCTAssertEqual(chunk?.prefix, "GH")
        XCTAssertEqual(chunk?.chapter, 99)
        XCTAssertEqual(chunk?.fileNumber, 1234)
    }

    // MARK: - Parse GX prefix

    func testParseGX_basic() {
        let chunk = GoProNameParser.parse("GX010001.MP4")
        XCTAssertNotNil(chunk)
        XCTAssertEqual(chunk?.prefix, "GX")
        XCTAssertEqual(chunk?.chapter, 1)
        XCTAssertEqual(chunk?.fileNumber, 1)
    }

    func testParseGX_variant() {
        let chunk = GoProNameParser.parse("GX030042.MP4")
        XCTAssertNotNil(chunk)
        XCTAssertEqual(chunk?.prefix, "GX")
        XCTAssertEqual(chunk?.chapter, 3)
        XCTAssertEqual(chunk?.fileNumber, 42)
    }

    // MARK: - Rejection cases

    func testReject_lowercase() {
        XCTAssertNil(GoProNameParser.parse("gh010001.MP4"))
    }

    func testReject_unknownPrefix() {
        XCTAssertNil(GoProNameParser.parse("GP010001.MP4"))
    }

    func testReject_randomName() {
        XCTAssertNil(GoProNameParser.parse("movie.mp4"))
    }

    func testReject_truncated() {
        XCTAssertNil(GoProNameParser.parse("GH0100.MP4"))
    }

    func testReject_noExtension() {
        XCTAssertNil(GoProNameParser.parse("GH010001"))
    }

    func testReject_wrongExtension() {
        XCTAssertNil(GoProNameParser.parse("GH010001.MOV"))
    }

    // MARK: - Sorting

    func testSort_singleSession() {
        let chunks = [
            GoProChunk(prefix: "GH", chapter: 2, fileNumber: 1),
            GoProChunk(prefix: "GH", chapter: 1, fileNumber: 1),
            GoProChunk(prefix: "GH", chapter: 3, fileNumber: 1),
        ]
        let sorted = GoProNameParser.sortedChunks(chunks)
        XCTAssertEqual(sorted[0].chapter, 1)
        XCTAssertEqual(sorted[1].chapter, 2)
        XCTAssertEqual(sorted[2].chapter, 3)
    }

    func testSort_multiSession() {
        // Multiple fileNumbers: sort by fileNumber asc, then chapter asc
        let chunks = [
            GoProChunk(prefix: "GH", chapter: 1, fileNumber: 2),
            GoProChunk(prefix: "GH", chapter: 2, fileNumber: 1),
            GoProChunk(prefix: "GH", chapter: 1, fileNumber: 1),
        ]
        let sorted = GoProNameParser.sortedChunks(chunks)
        XCTAssertEqual(sorted[0], GoProChunk(prefix: "GH", chapter: 1, fileNumber: 1))
        XCTAssertEqual(sorted[1], GoProChunk(prefix: "GH", chapter: 2, fileNumber: 1))
        XCTAssertEqual(sorted[2], GoProChunk(prefix: "GH", chapter: 1, fileNumber: 2))
    }

    func testSort_empty() {
        let sorted = GoProNameParser.sortedChunks([])
        XCTAssertTrue(sorted.isEmpty)
    }

    // MARK: - Equatable

    func testEquatable() {
        let a = GoProChunk(prefix: "GH", chapter: 1, fileNumber: 1)
        let b = GoProChunk(prefix: "GH", chapter: 1, fileNumber: 1)
        let c = GoProChunk(prefix: "GX", chapter: 1, fileNumber: 1)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // MARK: - Computed filename

    func testChunkFilename() {
        let chunk = GoProChunk(prefix: "GH", chapter: 1, fileNumber: 1)
        XCTAssertEqual(chunk.filename, "GH010001.MP4")
    }

    func testChunkFilename_padded() {
        let chunk = GoProChunk(prefix: "GX", chapter: 5, fileNumber: 23)
        XCTAssertEqual(chunk.filename, "GX050023.MP4")
    }
}
