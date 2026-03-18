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
    /// Progress callback receives `(secondsProcessed, totalDurationSeconds)`.
    /// Called periodically during extraction. Both values are in seconds.
    public typealias ProgressCallback = (_ secondsProcessed: Double, _ totalSeconds: Double) -> Void

    public static func extract(url: URL, progress: ProgressCallback? = nil) throws -> URL {
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

        // 4. Get total duration for progress calculation
        let totalDuration = probeDuration(ffmpegPath: ffmpeg, url: url)

        // 5. Run ffmpeg with progress output to stdout
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpeg)
        process.arguments = [
            "-y",
            "-i", url.path,
            "-vn",
            "-acodec", "libmp3lame",
            "-b:a", "320k",
            "-progress", "pipe:1",
            outputURL.path
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        // Parse progress from stdout in a background thread
        if let progress = progress, let total = totalDuration, total > 0 {
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
                // ffmpeg progress output contains lines like "out_time_us=12345678"
                for line in text.components(separatedBy: "\n") {
                    if line.hasPrefix("out_time_us=") {
                        let value = line.dropFirst("out_time_us=".count)
                        if let microseconds = Double(value) {
                            let seconds = microseconds / 1_000_000
                            progress(seconds, total)
                        }
                    }
                }
            }
        } else {
            process.standardOutput = FileHandle.nullDevice
        }

        try process.run()
        process.waitUntilExit()

        // Clean up handler
        pipe.fileHandleForReading.readabilityHandler = nil

        // 6. Check exit code
        guard process.terminationStatus == 0 else {
            throw AudioExtractorError.extractionFailed("exit code \(process.terminationStatus)")
        }

        return outputURL
    }

    /// Uses ffprobe to get the duration of the input file in seconds.
    private static func probeDuration(ffmpegPath: String, url: URL) -> Double? {
        let ffprobePath = ffmpegPath.replacingOccurrences(of: "ffmpeg", with: "ffprobe")
        guard FileManager.default.fileExists(atPath: ffprobePath) else { return nil }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffprobePath)
        process.arguments = [
            "-v", "error",
            "-show_entries", "format=duration",
            "-of", "default=noprint_wrappers=1:nokey=1",
            url.path
        ]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               let duration = Double(text) {
                return duration
            }
        } catch {}
        return nil
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
