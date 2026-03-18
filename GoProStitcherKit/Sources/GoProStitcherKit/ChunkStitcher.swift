import Foundation

/// Errors thrown by ChunkStitcher.
public enum ChunkStitcherError: Error, LocalizedError, Equatable {
    /// Fewer than 2 chunks were provided.
    case empty
    /// The first chunk (destination) does not exist on disk.
    case destinationNotFound
    /// A source chunk (index 1..N-1) does not exist on disk.
    case sourceNotFound(URL)
    /// ffmpeg process failed.
    case ffmpegFailed(String)

    public var errorDescription: String? {
        switch self {
        case .empty:
            return "At least 2 chunks are required for stitching."
        case .destinationNotFound:
            return "Destination file (first chunk) does not exist."
        case .sourceNotFound(let url):
            return "Source chunk does not exist: \(url.path)"
        case .ffmpegFailed(let msg):
            return "ffmpeg failed: \(msg)"
        }
    }
}

/// Stitches GoPro MP4 chunks into a single playable file using ffmpeg concat demuxer.
/// Uses `-c copy` (no re-encoding) so it's fast and preserves original quality.
/// Source chunks are deleted after successful stitching to save disk space.
public enum ChunkStitcher {

    /// Stitches an ordered array of chunk files into a single MP4.
    ///
    /// Uses ffmpeg concat demuxer with `-c copy` — remuxes container metadata
    /// without re-encoding. The output replaces `chunks[0]`.
    ///
    /// - Parameters:
    ///   - chunks: Ordered list of chunk URLs. Output replaces `chunks[0]`.
    ///   - progress: Optional callback fired after each source chunk is processed.
    ///     Receives `(completedIndex, totalSources)` where completedIndex is 1-based.
    /// - Throws: `ChunkStitcherError` on validation or ffmpeg failure.
    public static func stitch(chunks: [URL], progress: ((Int, Int) -> Void)? = nil) throws {
        guard chunks.count >= 2 else {
            throw ChunkStitcherError.empty
        }

        let destination = chunks[0]
        guard FileManager.default.fileExists(atPath: destination.path) else {
            throw ChunkStitcherError.destinationNotFound
        }

        // Validate all sources exist before starting
        for source in chunks[1...] {
            guard FileManager.default.fileExists(atPath: source.path) else {
                throw ChunkStitcherError.sourceNotFound(source)
            }
        }

        let sourceDir = destination.deletingLastPathComponent()
        let concatListURL = sourceDir.appendingPathComponent(".gopro_concat_list.txt")
        let tempOutputURL = sourceDir.appendingPathComponent(".gopro_stitched_temp.mp4")

        defer {
            // Clean up temp files
            try? FileManager.default.removeItem(at: concatListURL)
        }

        // Write ffmpeg concat list file
        let concatList = chunks.map { "file '\($0.path)'" }.joined(separator: "\n")
        try concatList.write(to: concatListURL, atomically: true, encoding: .utf8)

        // Find ffmpeg
        let ffmpegPath = ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"]
            .first { FileManager.default.fileExists(atPath: $0) }
        guard let ffmpeg = ffmpegPath else {
            throw ChunkStitcherError.ffmpegFailed("ffmpeg not found. Install with: brew install ffmpeg")
        }

        // Run ffmpeg concat demuxer with -c copy (no re-encoding)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpeg)
        process.arguments = [
            "-y",                       // overwrite output
            "-f", "concat",             // concat demuxer
            "-safe", "0",               // allow absolute paths
            "-i", concatListURL.path,   // input list
            "-c", "copy",               // no re-encoding
            tempOutputURL.path          // temp output
        ]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            // Clean up temp output on failure
            try? FileManager.default.removeItem(at: tempOutputURL)
            throw ChunkStitcherError.ffmpegFailed("exit code \(process.terminationStatus)")
        }

        // Delete all source chunks to free disk space
        let total = chunks.count
        for (index, chunk) in chunks.enumerated() {
            try FileManager.default.removeItem(at: chunk)
            progress?(index + 1, total)
        }

        // Move temp output to destination path (chunks[0])
        try FileManager.default.moveItem(at: tempOutputURL, to: destination)
    }
}
