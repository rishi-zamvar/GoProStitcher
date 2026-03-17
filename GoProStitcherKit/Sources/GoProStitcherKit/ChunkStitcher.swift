import Foundation

/// Errors thrown by ChunkStitcher.
public enum ChunkStitcherError: Error, LocalizedError, Equatable {
    /// Fewer than 2 chunks were provided.
    case empty
    /// The first chunk (destination) does not exist on disk.
    case destinationNotFound
    /// A source chunk (index 1..N-1) does not exist on disk.
    case sourceNotFound(URL)

    public var errorDescription: String? {
        switch self {
        case .empty:
            return "At least 2 chunks are required for stitching."
        case .destinationNotFound:
            return "Destination file (first chunk) does not exist."
        case .sourceNotFound(let url):
            return "Source chunk does not exist: \(url.path)"
        }
    }
}

/// Appends chunks[1..N-1] onto chunks[0] in-place using FileHandle with a 1 MB read buffer.
/// Source files are removed from disk after being appended.
public enum ChunkStitcher {
    private static let bufferSize = 1024 * 1024 // 1 MB

    /// Stitches an ordered array of chunk files into a single file.
    ///
    /// - Parameter chunks: Ordered list of chunk URLs. `chunks[0]` is the destination
    ///   (modified in-place). `chunks[1...]` are read and appended, then deleted.
    /// - Throws: `ChunkStitcherError.empty` if fewer than 2 chunks provided,
    ///   `ChunkStitcherError.destinationNotFound` if chunks[0] is missing,
    ///   `ChunkStitcherError.sourceNotFound` if any subsequent chunk is missing.
    public static func stitch(chunks: [URL]) throws {
        guard chunks.count >= 2 else {
            throw ChunkStitcherError.empty
        }

        let destination = chunks[0]
        guard FileManager.default.fileExists(atPath: destination.path) else {
            throw ChunkStitcherError.destinationNotFound
        }

        // Validate all sources exist before we start modifying anything
        for source in chunks[1...] {
            guard FileManager.default.fileExists(atPath: source.path) else {
                throw ChunkStitcherError.sourceNotFound(source)
            }
        }

        // Open destination for writing
        let destinationHandle = try FileHandle(forWritingTo: destination)
        defer { try? destinationHandle.close() }

        for source in chunks[1...] {
            try appendFile(from: source, to: destinationHandle)
            try FileManager.default.removeItem(at: source)
        }
    }

    /// Reads `source` in 1 MB chunks and appends each chunk to `destinationHandle`.
    private static func appendFile(from source: URL, to destinationHandle: FileHandle) throws {
        let sourceHandle = try FileHandle(forReadingFrom: source)
        defer { try? sourceHandle.close() }

        // Seek destination to end before appending
        try destinationHandle.seekToEnd()

        while true {
            let chunk: Data
            if #available(macOS 10.15.4, *) {
                guard let data = try sourceHandle.read(upToCount: bufferSize), !data.isEmpty else {
                    break
                }
                chunk = data
            } else {
                let data = sourceHandle.readData(ofLength: bufferSize)
                if data.isEmpty { break }
                chunk = data
            }

            if #available(macOS 10.15.4, *) {
                try destinationHandle.write(contentsOf: chunk)
            } else {
                destinationHandle.write(chunk)
            }
        }
    }
}
