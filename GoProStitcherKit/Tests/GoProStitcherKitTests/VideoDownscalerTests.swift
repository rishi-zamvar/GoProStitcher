import XCTest
@testable import GoProStitcherKit

final class VideoDownscalerTests: XCTestCase {

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

    private var ffmpegPath: String? {
        ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"]
            .first { FileManager.default.fileExists(atPath: $0) }
    }

    /// Generates a short synthetic 4K (3840x2160) MP4 using ffmpeg lavfi.
    /// Duration: 2 seconds. Returns URL of created file.
    private func make4KFixture(named name: String) throws -> URL {
        guard let ffmpeg = ffmpegPath else {
            throw XCTSkip("ffmpeg not available")
        }
        let dest = tempDir.appendingPathComponent(name)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpeg)
        process.arguments = [
            "-y",
            "-f", "lavfi", "-i", "color=c=blue:size=3840x2160:rate=30",
            "-f", "lavfi", "-i", "sine=frequency=440:duration=2",
            "-t", "2",
            "-c:v", "libx264", "-preset", "ultrafast", "-crf", "35",
            "-c:a", "aac",
            dest.path
        ]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "test", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "lavfi 4K fixture generation failed"])
        }
        return dest
    }

    /// Generates a short synthetic 1080p (1920x1080) MP4 using ffmpeg lavfi.
    /// Duration: 2 seconds. Returns URL of created file.
    private func make1080pFixture(named name: String) throws -> URL {
        guard let ffmpeg = ffmpegPath else {
            throw XCTSkip("ffmpeg not available")
        }
        let dest = tempDir.appendingPathComponent(name)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpeg)
        process.arguments = [
            "-y",
            "-f", "lavfi", "-i", "color=c=red:size=1920x1080:rate=30",
            "-f", "lavfi", "-i", "sine=frequency=440:duration=2",
            "-t", "2",
            "-c:v", "libx264", "-preset", "ultrafast", "-crf", "35",
            "-c:a", "aac",
            dest.path
        ]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "test", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "1080p fixture generation failed"])
        }
        return dest
    }

    // MARK: - Test 1: ffmpegNotFound

    func testDownscale_ffmpegNotFound_throwsTypedError() throws {
        try XCTSkipIf(ffmpegPresent, "ffmpeg is present on this machine — cannot test ffmpegNotFound path")

        let dummyURL = tempDir.appendingPathComponent("dummy.MP4")
        // Create a dummy file so input-validation doesn't fire first
        try Data(count: 16).write(to: dummyURL)

        XCTAssertThrowsError(try VideoDownscaler.downscale(url: dummyURL, outputName: "out.mp4")) { error in
            guard let downscalerError = error as? VideoDownscalerError else {
                XCTFail("Expected VideoDownscalerError, got \(error)")
                return
            }
            if case .ffmpegNotFound = downscalerError { } else {
                XCTFail("Expected .ffmpegNotFound, got \(downscalerError)")
            }
        }
    }

    // MARK: - Test 2: inputNotFound

    func testDownscale_inputNotFound_throwsTypedError() throws {
        try XCTSkipUnless(ffmpegPresent, "ffmpeg not available on this machine")

        let nonexistent = tempDir.appendingPathComponent("does_not_exist.MP4")

        XCTAssertThrowsError(try VideoDownscaler.downscale(url: nonexistent, outputName: "out.mp4")) { error in
            guard let downscalerError = error as? VideoDownscalerError else {
                XCTFail("Expected VideoDownscalerError, got \(error)")
                return
            }
            if case .inputNotFound(let url) = downscalerError {
                XCTAssertEqual(url, nonexistent)
            } else {
                XCTFail("Expected .inputNotFound, got \(downscalerError)")
            }
        }
    }

    // MARK: - Test 3: alreadyAtTargetResolution

    func testDownscale_alreadyAtTargetResolution_throwsTypedError() throws {
        try XCTSkipUnless(ffmpegPresent, "ffmpeg not available on this machine")

        let source = try make1080pFixture(named: "source_1080p.mp4")

        XCTAssertThrowsError(try VideoDownscaler.downscale(url: source, outputName: "out_1080p.mp4")) { error in
            guard let downscalerError = error as? VideoDownscalerError else {
                XCTFail("Expected VideoDownscalerError, got \(error)")
                return
            }
            if case .alreadyAtTargetResolution = downscalerError { } else {
                XCTFail("Expected .alreadyAtTargetResolution, got \(downscalerError)")
            }
        }
    }

    // MARK: - Test 4: encoding produces 1080p output

    func testDownscale_encoding_produces1080pOutput() throws {
        try XCTSkipUnless(ffmpegPresent, "ffmpeg not available on this machine")

        let source = try make4KFixture(named: "source_4k.mp4")
        let output = try VideoDownscaler.downscale(url: source, outputName: "out_1080p.mp4")

        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path),
                      "Output file should exist on disk")

        let attrs = try FileManager.default.attributesOfItem(atPath: output.path)
        let size = attrs[.size] as? Int ?? 0
        XCTAssertGreaterThan(size, 0, "Output file should have non-zero size")

        // Verify output is actually 1080p via ffprobe
        guard let ffprobe = ffmpegPath.map({ $0.replacingOccurrences(of: "ffmpeg", with: "ffprobe") }),
              FileManager.default.fileExists(atPath: ffprobe) else {
            return // ffprobe unavailable, skip height check
        }
        let probeProcess = Process()
        probeProcess.executableURL = URL(fileURLWithPath: ffprobe)
        probeProcess.arguments = [
            "-v", "error",
            "-select_streams", "v:0",
            "-show_entries", "stream=height",
            "-of", "default=noprint_wrappers=1:nokey=1",
            output.path
        ]
        let probePipe = Pipe()
        probeProcess.standardOutput = probePipe
        probeProcess.standardError = FileHandle.nullDevice
        try probeProcess.run()
        probeProcess.waitUntilExit()
        let probeData = probePipe.fileHandleForReading.readDataToEndOfFile()
        let heightStr = String(data: probeData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        XCTAssertEqual(heightStr, "1080", "Output height should be 1080 pixels")
    }

    // MARK: - Test 5: audio preserved

    func testDownscale_encoding_audioPreserved() throws {
        try XCTSkipUnless(ffmpegPresent, "ffmpeg not available on this machine")

        let source = try make4KFixture(named: "source_4k_audio.mp4")
        let output = try VideoDownscaler.downscale(url: source, outputName: "out_audio.mp4")

        guard let ffprobe = ffmpegPath.map({ $0.replacingOccurrences(of: "ffmpeg", with: "ffprobe") }),
              FileManager.default.fileExists(atPath: ffprobe) else {
            return // ffprobe unavailable
        }
        let probeProcess = Process()
        probeProcess.executableURL = URL(fileURLWithPath: ffprobe)
        probeProcess.arguments = [
            "-v", "error",
            "-show_entries", "stream=codec_type",
            "-of", "default=noprint_wrappers=1:nokey=1",
            output.path
        ]
        let probePipe = Pipe()
        probeProcess.standardOutput = probePipe
        probeProcess.standardError = FileHandle.nullDevice
        try probeProcess.run()
        probeProcess.waitUntilExit()
        let probeData = probePipe.fileHandleForReading.readDataToEndOfFile()
        let streamsStr = String(data: probeData, encoding: .utf8) ?? ""
        XCTAssertTrue(streamsStr.contains("audio"),
                      "Output should contain an audio stream — audio should be copied through")
    }

    // MARK: - Test 6: collision appends _1 suffix

    func testDownscale_collision_appendsSuffix() throws {
        try XCTSkipUnless(ffmpegPresent, "ffmpeg not available on this machine")

        let source = try make4KFixture(named: "source.MP4")

        // Pre-create the target name to force collision
        let existing = tempDir.appendingPathComponent("source_1080p.mp4")
        try Data(count: 8).write(to: existing)

        let output = try VideoDownscaler.downscale(url: source, outputName: "source_1080p.mp4")

        XCTAssertEqual(output.lastPathComponent, "source_1080p_1.mp4",
                       "When source_1080p.mp4 already exists, output should be source_1080p_1.mp4")
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path),
                      "Collision-resolved output file should exist on disk")

        let attrs = try FileManager.default.attributesOfItem(atPath: output.path)
        let size = attrs[.size] as? Int ?? 0
        XCTAssertGreaterThan(size, 0, "Collision-resolved output should have non-zero size")
    }

    // MARK: - Test 7: double collision appends _2 suffix

    func testDownscale_doubleCollision_appendsIncrementingSuffix() throws {
        try XCTSkipUnless(ffmpegPresent, "ffmpeg not available on this machine")

        let source = try make4KFixture(named: "source.MP4")

        // Pre-create both the base name and the _1 variant
        let existing0 = tempDir.appendingPathComponent("source_1080p.mp4")
        let existing1 = tempDir.appendingPathComponent("source_1080p_1.mp4")
        try Data(count: 8).write(to: existing0)
        try Data(count: 8).write(to: existing1)

        let output = try VideoDownscaler.downscale(url: source, outputName: "source_1080p.mp4")

        XCTAssertEqual(output.lastPathComponent, "source_1080p_2.mp4",
                       "When source_1080p.mp4 and source_1080p_1.mp4 exist, output should be source_1080p_2.mp4")
    }

    // MARK: - Test 8: progress callback fires

    func testDownscale_progressCallback_fires() throws {
        try XCTSkipUnless(ffmpegPresent, "ffmpeg not available on this machine")

        let source = try make4KFixture(named: "source_progress.mp4")

        var receivedProgress: [DownscaleProgress] = []
        _ = try VideoDownscaler.downscale(url: source, outputName: "out_progress.mp4") { p in
            receivedProgress.append(p)
        }

        XCTAssertGreaterThan(receivedProgress.count, 0,
                             "Progress callback should fire at least once during encoding")
        XCTAssertGreaterThan(receivedProgress.first!.totalSeconds, 0,
                             "totalSeconds should be positive")
        for p in receivedProgress {
            XCTAssertTrue((0.0...1.0).contains(p.fraction),
                          "All fraction values should be in 0.0...1.0 range, got \(p.fraction)")
        }
    }
}
