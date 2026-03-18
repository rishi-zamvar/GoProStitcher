import Foundation

/// Extracts the audio track from a video file into a 320 kbps MP3 using ffmpeg.
public enum AudioExtractor {

    /// Extracts audio from the video at `url` and returns the URL of the produced MP3.
    ///
    /// The output file is placed in the same directory as the source. If a file with the
    /// target name already exists, a numeric suffix is appended (_1, _2, …) until a
    /// free path is found (up to _999).
    ///
    /// - Parameter url: URL of the input video file.
    /// - Returns: URL of the newly created MP3 file.
    /// - Throws: `AudioExtractorError` on validation or ffmpeg failure.
    public static func extract(url: URL) throws -> URL {
        // 1. Find ffmpeg
        let ffmpegPath = ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"]
            .first { FileManager.default.fileExists(atPath: $0) }
        guard let ffmpeg = ffmpegPath else {
            throw AudioExtractorError.ffmpegNotFound
        }

        // 2. Validate input exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AudioExtractorError.inputNotFound(url)
        }

        // 3. Compute collision-free output path
        let sourceDir = url.deletingLastPathComponent()
        let stem = url.deletingPathExtension().lastPathComponent
        let outputURL = try collisionFreeURL(in: sourceDir, stem: stem, ext: "mp3")

        // 4. Run ffmpeg: strip video (-vn), encode to MP3 at 320 kbps
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpeg)
        process.arguments = [
            "-y",
            "-i", url.path,
            "-vn",
            "-acodec", "libmp3lame",
            "-b:a", "320k",
            outputURL.path
        ]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        // 5. Check exit code
        guard process.terminationStatus == 0 else {
            throw AudioExtractorError.extractionFailed("exit code \(process.terminationStatus)")
        }

        return outputURL
    }

    // MARK: - Private helpers

    /// Returns a path that does not yet exist on disk.
    /// Tries `stem.ext`, then `stem_1.ext`, `stem_2.ext`, … up to `stem_999.ext`.
    private static func collisionFreeURL(in directory: URL, stem: String, ext: String) throws -> URL {
        let base = directory.appendingPathComponent("\(stem).\(ext)")
        if !FileManager.default.fileExists(atPath: base.path) {
            return base
        }
        for suffix in 1...999 {
            let candidate = directory.appendingPathComponent("\(stem)_\(suffix).\(ext)")
            if !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        throw AudioExtractorError.outputWriteFailed("Could not find a free output path for \(stem).\(ext) after 999 attempts")
    }
}
