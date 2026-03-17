import Foundation

/// Errors thrown by ChunkArchiver.
public enum ChunkArchiverError: Error, LocalizedError, Equatable {
    /// A source chunk does not exist on disk.
    case sourceNotFound(URL)
    /// The /usr/bin/zip process exited with a non-zero status.
    case zipFailed(URL, Int)

    public var errorDescription: String? {
        switch self {
        case .sourceNotFound(let url):
            return "Source chunk does not exist: \(url.path)"
        case .zipFailed(let url, let exitCode):
            return "zip failed for \(url.lastPathComponent) with exit code \(exitCode)"
        }
    }
}

/// Creates an individual zip archive for each chunk inside a target archive directory.
public enum ChunkArchiver {
    /// Archives each chunk into `archiveDir/<filename>.zip` using `/usr/bin/zip -j`.
    ///
    /// - Parameters:
    ///   - chunks: Source chunk URLs to archive.
    ///   - archiveDir: Directory where zip files will be created. Created if it doesn't exist.
    ///   - progress: Optional callback receiving `(current, total)` after each chunk is zipped.
    /// - Throws: `ChunkArchiverError.sourceNotFound` if a chunk is missing,
    ///   `ChunkArchiverError.zipFailed` if zip exits with non-zero status.
    public static func archive(
        chunks: [URL],
        into archiveDir: URL,
        progress: ((Int, Int) -> Void)? = nil
    ) throws {
        // Validate all sources before starting
        for chunk in chunks {
            guard FileManager.default.fileExists(atPath: chunk.path) else {
                throw ChunkArchiverError.sourceNotFound(chunk)
            }
        }

        // Create archive directory if needed
        try FileManager.default.createDirectory(at: archiveDir, withIntermediateDirectories: true)

        let total = chunks.count
        for (index, chunk) in chunks.enumerated() {
            let zipName = chunk.lastPathComponent + ".zip"
            let zipURL = archiveDir.appendingPathComponent(zipName)

            try runZip(source: chunk, destination: zipURL)

            progress?(index + 1, total)
        }
    }

    /// Runs `/usr/bin/zip -j <destination> <source>` synchronously.
    private static func runZip(source: URL, destination: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        // -j: junk paths (store just the file, not full path)
        process.arguments = ["-j", destination.path, source.path]

        // Suppress output
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        let exitCode = Int(process.terminationStatus)
        guard exitCode == 0 else {
            throw ChunkArchiverError.zipFailed(source, exitCode)
        }
    }
}
