import Foundation

/// Downscales a video file to 1080p H.264 using ffmpeg.
public enum VideoDownscaler {

    /// Progress callback type received during encoding.
    public typealias ProgressCallback = (_ progress: DownscaleProgress) -> Void

    /// Downscales the video at `url` to 1080p H.264 and returns the URL of the produced MP4.
    ///
    /// The output file is placed in the same directory as the source. If a file with the
    /// target name already exists, a numeric suffix is appended (_1, _2, …) until a
    /// free path is found (up to _999).
    ///
    /// - Parameters:
    ///   - url: URL of the input video file.
    ///   - outputName: Desired filename for the output (e.g. "clip_1080p.mp4").
    ///   - progress: Optional callback fired periodically during encoding.
    /// - Returns: URL of the newly created MP4 file.
    /// - Throws: `VideoDownscalerError` on validation or ffmpeg failure.
    public static func downscale(url: URL, outputName: String, progress: ProgressCallback? = nil) throws -> URL {
        // 1. Find ffmpeg
        let ffmpegPath = ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"]
            .first { FileManager.default.fileExists(atPath: $0) }
        guard let ffmpeg = ffmpegPath else {
            throw VideoDownscalerError.ffmpegNotFound
        }

        // 2. Validate input exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw VideoDownscalerError.inputNotFound(url)
        }

        // 3. Resolution guard via ffprobe — block if already at or below 1080p
        if let height = probeResolution(ffmpegPath: ffmpeg, url: url), height <= 1080 {
            throw VideoDownscalerError.alreadyAtTargetResolution
        }

        // 4. Compute collision-free output path
        let sourceDir = url.deletingLastPathComponent()
        let safeName = URL(fileURLWithPath: outputName).lastPathComponent
        let outputURL = try collisionFreeURL(in: sourceDir, name: safeName)

        // 5. Defer partial cleanup on failure
        var cleanupOnFailure = true
        defer {
            if cleanupOnFailure {
                try? FileManager.default.removeItem(at: outputURL)
            }
        }

        // 6. Probe total duration for progress fraction calculation
        let totalDuration = probeDuration(ffmpegPath: ffmpeg, url: url)

        // 7. Build ffmpeg process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpeg)
        process.arguments = [
            "-y",
            "-i", url.path,
            "-vf", "scale=-2:1080",
            "-c:v", "libx264",
            "-preset", "slow",
            "-crf", "18",
            "-c:a", "copy",
            "-progress", "pipe:1",
            outputURL.path
        ]
        process.standardError = FileHandle.nullDevice

        // 8. Parse progress from pipe when callback is provided
        let pipe = Pipe()
        if progress != nil, let total = totalDuration, total > 0 {
            process.standardOutput = pipe
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }

                var secondsProcessed: Double = 0
                var bitrateKbps: Double = 0
                var fps: Double = 0
                var didSeeOutTime = false

                for line in text.components(separatedBy: "\n") {
                    if line.hasPrefix("out_time_us=") {
                        let value = line.dropFirst("out_time_us=".count)
                        if let microseconds = Double(value) {
                            secondsProcessed = microseconds / 1_000_000
                            didSeeOutTime = true
                        }
                    } else if line.hasPrefix("bitrate=") {
                        let raw = line.dropFirst("bitrate=".count)
                        // raw looks like "1234.5kbits/s" or "N/A"
                        let digits = raw.components(separatedBy: "k").first ?? ""
                        bitrateKbps = Double(digits) ?? 0
                    } else if line.hasPrefix("fps=") {
                        let value = line.dropFirst("fps=".count)
                        fps = Double(value) ?? 0
                    }
                }

                if didSeeOutTime {
                    let fraction = min(secondsProcessed / total, 1.0)
                    let p = DownscaleProgress(
                        fraction: fraction,
                        secondsProcessed: secondsProcessed,
                        totalSeconds: total,
                        bitrateKbps: bitrateKbps,
                        fps: fps
                    )
                    progress?(p)
                }
            }
        } else {
            process.standardOutput = FileHandle.nullDevice
        }

        // 9. Run and wait
        try process.run()
        process.waitUntilExit()

        // Clean up readability handler
        pipe.fileHandleForReading.readabilityHandler = nil

        // 10. Check exit code
        guard process.terminationStatus == 0 else {
            throw VideoDownscalerError.encodingFailed("exit code \(process.terminationStatus)")
        }

        // 11. Return
        cleanupOnFailure = false
        return outputURL
    }

    // MARK: - Private helpers

    /// Uses ffprobe to determine the height of the first video stream.
    /// Returns nil if ffprobe is unavailable or the height cannot be parsed.
    private static func probeResolution(ffmpegPath: String, url: URL) -> Int? {
        let ffprobePath = ffmpegPath.replacingOccurrences(of: "ffmpeg", with: "ffprobe")
        guard FileManager.default.fileExists(atPath: ffprobePath) else { return nil }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffprobePath)
        process.arguments = [
            "-v", "error",
            "-select_streams", "v:0",
            "-show_entries", "stream=height",
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
            if let text = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               let height = Int(text) {
                return height
            }
        } catch {}
        return nil
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
            if let text = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               let duration = Double(text) {
                return duration
            }
        } catch {}
        return nil
    }

    /// Returns a path that does not yet exist on disk.
    /// Tries `name` first, then `stem_1.ext`, `stem_2.ext`, … up to `stem_999.ext`.
    private static func collisionFreeURL(in directory: URL, name: String) throws -> URL {
        let parts = name.components(separatedBy: ".")
        let ext = parts.last ?? "mp4"
        let stem = parts.dropLast().joined(separator: ".")

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
        throw VideoDownscalerError.outputWriteFailed(
            "Could not find a free output path for \(name) after 999 attempts"
        )
    }
}
