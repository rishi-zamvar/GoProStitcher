import Foundation

/// A scanned chunk paired with its on-disk URL and file size.
public struct ScannedChunk: Equatable {
    /// The parsed GoPro chunk metadata.
    public let chunk: GoProChunk
    /// Absolute file URL of the chunk on disk.
    public let url: URL
    /// Size of the file in bytes.
    public let sizeBytes: Int

    public init(chunk: GoProChunk, url: URL, sizeBytes: Int) {
        self.chunk = chunk
        self.url = url
        self.sizeBytes = sizeBytes
    }
}

/// The result of scanning a directory for GoPro video chunks.
public enum FolderScanResult {
    /// At least one GoPro chunk was found. Chunks are sorted by fileNumber asc, then chapter asc.
    case success([ScannedChunk])
    /// Directory contained no files at all (or only non-MP4 files).
    case empty
    /// Directory contained MP4 files but none matched the GoPro naming convention.
    case noGoProFiles
}

/// Scans a directory URL and identifies GoPro video chunks using ``GoProNameParser``.
///
/// Usage:
/// ```swift
/// let result = FolderScanner.scan(url: folderURL)
/// ```
public enum FolderScanner {

    /// Scans the directory at `url` for GoPro video chunks.
    ///
    /// - Parameter url: A directory URL to scan. Must be a directory (not a file).
    /// - Returns: A ``FolderScanResult`` describing what was found.
    public static func scan(url: URL) -> FolderScanResult {
        let fm = FileManager.default

        // List directory contents — silently return .empty if listing fails
        guard let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return .empty
        }

        // Filter to .MP4 files only (case-sensitive to match GoPro convention)
        let mp4Files = contents.filter { $0.pathExtension == "MP4" }

        // No MP4s at all → .empty
        guard !mp4Files.isEmpty else {
            return .empty
        }

        // Parse each MP4 filename using GoProNameParser
        var scannedChunks: [ScannedChunk] = []
        for fileURL in mp4Files {
            let filename = fileURL.lastPathComponent
            guard let chunk = GoProNameParser.parse(filename) else {
                continue  // not a GoPro file — skip
            }

            // Read file size
            let sizeBytes: Int
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let size = resourceValues.fileSize {
                sizeBytes = size
            } else {
                sizeBytes = 0
            }

            scannedChunks.append(ScannedChunk(chunk: chunk, url: fileURL, sizeBytes: sizeBytes))
        }

        // All MP4s were non-GoPro → .noGoProFiles
        guard !scannedChunks.isEmpty else {
            return .noGoProFiles
        }

        // Sort into canonical stitch order: fileNumber asc, then chapter asc
        let sorted = scannedChunks.sorted {
            if $0.chunk.fileNumber != $1.chunk.fileNumber {
                return $0.chunk.fileNumber < $1.chunk.fileNumber
            }
            return $0.chunk.chapter < $1.chunk.chapter
        }

        return .success(sorted)
    }
}
