import XCTest
@testable import GoProStitcherKit

final class AudioExtractorTests: XCTestCase {
    private var tempDir: URL!

    // MARK: - Setup / Teardown

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

    private var ffmpegPresent: Bool {
        ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"]
            .contains { FileManager.default.fileExists(atPath: $0) }
    }

    /// Copies the MP4 fixture (with audio) to a temp location with the given name.
    /// Uses GH010001_audio.MP4 which contains both video and audio streams.
    private func copyFixture(named name: String) throws -> URL {
        guard let fixtureURL = Bundle.module.url(forResource: "GH010001_audio", withExtension: "MP4") else {
            throw NSError(domain: "test", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Fixture GH010001_audio.MP4 not found in bundle"])
        }
        let dest = tempDir.appendingPathComponent(name)
        try FileManager.default.copyItem(at: fixtureURL, to: dest)
        return dest
    }

    // MARK: - Test 1: ffmpegNotFound

    func testExtract_ffmpegNotFound() throws {
        try XCTSkipIf(ffmpegPresent, "ffmpeg is present on this machine — cannot test ffmpegNotFound path")

        let dummyURL = tempDir.appendingPathComponent("dummy.MP4")
        // Create a dummy file so input-validation doesn't fire first
        try Data(count: 16).write(to: dummyURL)

        XCTAssertThrowsError(try AudioExtractor.extract(url: dummyURL)) { error in
            guard let extractorError = error as? AudioExtractorError else {
                XCTFail("Expected AudioExtractorError, got \(error)")
                return
            }
            if case .ffmpegNotFound = extractorError { } else {
                XCTFail("Expected .ffmpegNotFound, got \(extractorError)")
            }
        }
    }

    // MARK: - Test 2: inputNotFound

    func testExtract_inputNotFound() {
        let nonexistent = tempDir.appendingPathComponent("does_not_exist.MP4")

        XCTAssertThrowsError(try AudioExtractor.extract(url: nonexistent)) { error in
            guard let extractorError = error as? AudioExtractorError else {
                XCTFail("Expected AudioExtractorError, got \(error)")
                return
            }
            if case .inputNotFound(let url) = extractorError {
                XCTAssertEqual(url, nonexistent)
            } else {
                XCTFail("Expected .inputNotFound, got \(extractorError)")
            }
        }
    }

    // MARK: - Test 3: collision — appends _1 suffix

    func testExtract_collision_appendsSuffix() throws {
        try XCTSkipUnless(ffmpegPresent, "ffmpeg not available on this machine")

        let source = try copyFixture(named: "GH010001.MP4")

        // Pre-create stem.mp3 to force collision
        let existingMP3 = tempDir.appendingPathComponent("GH010001.mp3")
        try Data(count: 8).write(to: existingMP3)

        let output = try AudioExtractor.extract(url: source)

        XCTAssertEqual(output.lastPathComponent, "GH010001_1.mp3",
                       "When stem.mp3 already exists, output should be stem_1.mp3")
    }

    // MARK: - Test 4: double collision — appends _2 suffix

    func testExtract_doubleCollision() throws {
        try XCTSkipUnless(ffmpegPresent, "ffmpeg not available on this machine")

        let source = try copyFixture(named: "GH010001.MP4")

        // Pre-create both stem.mp3 and stem_1.mp3
        let existing0 = tempDir.appendingPathComponent("GH010001.mp3")
        let existing1 = tempDir.appendingPathComponent("GH010001_1.mp3")
        try Data(count: 8).write(to: existing0)
        try Data(count: 8).write(to: existing1)

        let output = try AudioExtractor.extract(url: source)

        XCTAssertEqual(output.lastPathComponent, "GH010001_2.mp3",
                       "When stem.mp3 and stem_1.mp3 exist, output should be stem_2.mp3")
    }

    // MARK: - Test 5: successful extraction

    func testExtract_successfulExtraction() throws {
        try XCTSkipUnless(ffmpegPresent, "ffmpeg not available on this machine")

        let source = try copyFixture(named: "GH010001.MP4")

        let output = try AudioExtractor.extract(url: source)

        XCTAssertTrue(output.lastPathComponent.hasSuffix(".mp3"),
                      "Output should be an .mp3 file")
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path),
                      "Output .mp3 should exist on disk")

        let attrs = try FileManager.default.attributesOfItem(atPath: output.path)
        let size = attrs[.size] as? Int ?? 0
        XCTAssertGreaterThan(size, 0, "Output .mp3 should have non-zero size")
    }

    // MARK: - Test 6: output placed next to source

    func testExtract_outputNextToSource() throws {
        try XCTSkipUnless(ffmpegPresent, "ffmpeg not available on this machine")

        let source = try copyFixture(named: "GH010001.MP4")

        let output = try AudioExtractor.extract(url: source)

        let sourceDir = source.deletingLastPathComponent().standardized
        let outputDir = output.deletingLastPathComponent().standardized
        XCTAssertEqual(outputDir, sourceDir,
                       "Output should be placed in the same directory as the source file")
    }
}
