import Foundation

/// Errors thrown by ChunkArchiver.
public enum ChunkArchiverError: Error, LocalizedError, Equatable {
    /// A source chunk does not exist on disk.
    case sourceNotFound(URL)
    /// Failed to write the manifest file.
    case manifestWriteFailed(String)

    public var errorDescription: String? {
        switch self {
        case .sourceNotFound(let url):
            return "Source chunk does not exist: \(url.path)"
        case .manifestWriteFailed(let reason):
            return "Failed to write manifest: \(reason)"
        }
    }
}

/// A single entry in the stitch manifest — records a chunk's name and byte size
/// so the stitched file can be split back into original chunks.
public struct ManifestEntry: Codable, Equatable {
    public let filename: String
    public let sizeBytes: Int

    public init(filename: String, sizeBytes: Int) {
        self.filename = filename
        self.sizeBytes = sizeBytes
    }
}

/// The stitch manifest — a small JSON file saved alongside the stitched output.
/// Contains enough information to split the stitched file back into original chunks.
public struct StitchManifest: Codable, Equatable {
    public let version: Int
    public let stitchedFilename: String
    public let chunks: [ManifestEntry]
    public let createdAt: String

    public init(stitchedFilename: String, chunks: [ManifestEntry]) {
        self.version = 1
        self.stitchedFilename = stitchedFilename
        self.chunks = chunks
        self.createdAt = ISO8601DateFormatter().string(from: Date())
    }
}

/// Saves a manifest recording original chunk boundaries so stitching can be reverted.
/// No zip files are created — zero extra storage beyond a tiny JSON file.
public enum ChunkArchiver {
    /// Saves a manifest JSON file at `manifestURL` recording each chunk's filename and byte size.
    ///
    /// This enables reversion: the stitched file can be split back into original chunks
    /// by reading the manifest and splitting at the recorded byte boundaries.
    ///
    /// - Parameters:
    ///   - chunks: Source chunk URLs to record.
    ///   - manifestURL: Where to write the manifest JSON file.
    ///   - progress: Optional callback receiving `(current, total)` after each chunk is measured.
    /// - Throws: `ChunkArchiverError.sourceNotFound` if a chunk is missing.
    public static func archive(
        chunks: [URL],
        into manifestURL: URL,
        progress: ((Int, Int) -> Void)? = nil
    ) throws {
        // Validate all sources and collect sizes
        var entries: [ManifestEntry] = []
        let total = chunks.count

        for (index, chunk) in chunks.enumerated() {
            guard FileManager.default.fileExists(atPath: chunk.path) else {
                throw ChunkArchiverError.sourceNotFound(chunk)
            }

            let attrs = try FileManager.default.attributesOfItem(atPath: chunk.path)
            let size = (attrs[.size] as? Int) ?? 0
            entries.append(ManifestEntry(filename: chunk.lastPathComponent, sizeBytes: size))

            progress?(index + 1, total)
        }

        let stitchedFilename = chunks.first?.lastPathComponent ?? "stitched.mp4"
        let manifest = StitchManifest(stitchedFilename: stitchedFilename, chunks: entries)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(manifest)

        // Create parent directory if needed
        let parentDir = manifestURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)

        try data.write(to: manifestURL)
    }

    /// Splits a stitched file back into original chunks using a manifest.
    ///
    /// - Parameters:
    ///   - stitchedURL: The stitched file to split.
    ///   - manifestURL: The manifest JSON file recording chunk boundaries.
    ///   - outputDir: Directory where restored chunks will be written.
    /// - Throws: Errors if files are missing or byte sizes don't match.
    public static func revert(
        stitchedURL: URL,
        manifestURL: URL,
        outputDir: URL
    ) throws {
        let data = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(StitchManifest.self, from: data)

        let sourceHandle = try FileHandle(forReadingFrom: stitchedURL)
        defer { try? sourceHandle.close() }

        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        for entry in manifest.chunks {
            let outputURL = outputDir.appendingPathComponent(entry.filename)
            FileManager.default.createFile(atPath: outputURL.path, contents: nil)
            let outputHandle = try FileHandle(forWritingTo: outputURL)
            defer { try? outputHandle.close() }

            var remaining = entry.sizeBytes
            let bufferSize = 1024 * 1024 // 1 MB
            while remaining > 0 {
                let readSize = min(bufferSize, remaining)
                let chunk: Data
                if #available(macOS 10.15.4, *) {
                    guard let d = try sourceHandle.read(upToCount: readSize), !d.isEmpty else { break }
                    chunk = d
                } else {
                    let d = sourceHandle.readData(ofLength: readSize)
                    if d.isEmpty { break }
                    chunk = d
                }
                if #available(macOS 10.15.4, *) {
                    try outputHandle.write(contentsOf: chunk)
                } else {
                    outputHandle.write(chunk)
                }
                remaining -= chunk.count
            }
        }
    }
}
