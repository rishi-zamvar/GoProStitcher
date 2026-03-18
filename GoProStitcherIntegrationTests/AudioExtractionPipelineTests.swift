import XCTest
import GoProStitcherKit

final class AudioExtractionPipelineTests: XCTestCase {
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

    /// Creates an audio-bearing MP4 test fixture using ffmpeg.
    /// Uses a 440 Hz sine tone + silent video so the file has a valid audio track.
    private func makeAudioMP4(named name: String) throws -> URL {
        let dest = tempDir.appendingPathComponent(name)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/ffmpeg")
        process.arguments = [
            "-y",
            "-f", "lavfi", "-i", "sine=frequency=440:duration=2",
            "-f", "lavfi", "-i", "color=c=black:s=160x90:d=2",
            "-c:a", "aac", "-c:v", "libx264", "-pix_fmt", "yuv420p",
            "-shortest",
            dest.path
        ]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "test", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "ffmpeg fixture creation failed (exit \(process.terminationStatus))"])
        }
        return dest
    }

    func testExtractProducesNonEmptyMP3NextToSource() throws {
        let sourceURL = try makeAudioMP4(named: "test_audio.mp4")
        XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path), "Source fixture must exist")

        let outputURL = try AudioExtractor.extract(url: sourceURL)

        // 1. Output exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path),
                      "MP3 output file must exist at \(outputURL.path)")

        // 2. Non-empty
        let attrs = try FileManager.default.attributesOfItem(atPath: outputURL.path)
        let size = attrs[.size] as? Int64 ?? 0
        XCTAssertGreaterThan(size, 0, "MP3 must be non-empty")

        // 3. Extension is .mp3
        XCTAssertEqual(outputURL.pathExtension.lowercased(), "mp3")

        // 4. Same directory as source
        XCTAssertEqual(outputURL.deletingLastPathComponent().path,
                       sourceURL.deletingLastPathComponent().path,
                       "MP3 must be placed next to source file")
    }

    func testExtractCollisionAppendsNumericSuffix() throws {
        let sourceURL = try makeAudioMP4(named: "clip.mp4")

        // First extraction — produces clip.mp3
        let first = try AudioExtractor.extract(url: sourceURL)
        XCTAssertEqual(first.lastPathComponent, "clip.mp3")

        // Second extraction — clip.mp3 exists, should produce clip_1.mp3
        let second = try AudioExtractor.extract(url: sourceURL)
        XCTAssertEqual(second.lastPathComponent, "clip_1.mp3")

        // Both must exist and be non-empty
        for url in [first, second] {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            let size = (try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
            XCTAssertGreaterThan(size, 0)
        }
    }
}
