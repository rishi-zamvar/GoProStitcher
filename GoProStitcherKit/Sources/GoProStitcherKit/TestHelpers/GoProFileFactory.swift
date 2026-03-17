import Foundation

public struct GoProFileFactory {
    /// Pure name formatter — no file system access. Useful in tests that verify name parsing logic.
    /// Produces filenames like "GH010001.MP4".
    public static func goProName(prefix: String, chapter: Int, fileNumber: Int) -> String {
        return "\(prefix)\(String(format: "%02d", chapter))\(String(format: "%04d", fileNumber)).MP4"
    }

    /// Creates a zero-filled file at the GoPro-named path inside `directory`.
    ///
    /// - Parameters:
    ///   - directory: The directory in which to create the file.
    ///   - chapter: Chapter number (1-99). Encoded as 2-digit zero-padded string in filename.
    ///   - fileNumber: File number (1-9999). Encoded as 4-digit zero-padded string in filename.
    ///   - prefix: Must be "GH" (H.265 HEVC) or "GX" (H.264 AVC). Defaults to "GH".
    ///   - sizeBytes: Number of zero bytes to write. Defaults to 1024.
    /// - Returns: URL of the created file.
    @discardableResult
    public static func makeChunk(
        in directory: URL,
        chapter: Int,
        fileNumber: Int,
        prefix: String = "GH",
        sizeBytes: Int = 1024
    ) throws -> URL {
        guard prefix == "GH" || prefix == "GX" else {
            throw GoProFileFactoryError.invalidPrefix(prefix)
        }
        guard (1...99).contains(chapter) else {
            throw GoProFileFactoryError.invalidChapter(chapter)
        }
        guard (1...9999).contains(fileNumber) else {
            throw GoProFileFactoryError.invalidFileNumber(fileNumber)
        }

        let filename = goProName(prefix: prefix, chapter: chapter, fileNumber: fileNumber)
        let fileURL = directory.appendingPathComponent(filename)
        let data = Data(count: sizeBytes)
        try data.write(to: fileURL)
        return fileURL
    }

    /// Creates `count` chunks in `directory` with chapter numbers 1..count, fileNumber fixed.
    /// Returns URLs in correct stitch order (chapter 1 first).
    ///
    /// - Parameters:
    ///   - directory: The directory in which to create the files.
    ///   - count: Number of chunks to create.
    ///   - prefix: "GH" or "GX". Defaults to "GH".
    ///   - fileNumber: Fixed file number for all chunks. Defaults to 1.
    ///   - chunkSizeBytes: Size in bytes for each chunk. Defaults to 1024.
    /// - Returns: Array of file URLs in stitch order (chapter ascending).
    public static func makeSequence(
        in directory: URL,
        count: Int,
        prefix: String = "GH",
        fileNumber: Int = 1,
        chunkSizeBytes: Int = 1024
    ) throws -> [URL] {
        var urls: [URL] = []
        for chapter in 1...count {
            let url = try makeChunk(
                in: directory,
                chapter: chapter,
                fileNumber: fileNumber,
                prefix: prefix,
                sizeBytes: chunkSizeBytes
            )
            urls.append(url)
        }
        return urls
    }
}

public enum GoProFileFactoryError: Error, LocalizedError {
    case invalidPrefix(String)
    case invalidChapter(Int)
    case invalidFileNumber(Int)

    public var errorDescription: String? {
        switch self {
        case .invalidPrefix(let p):
            return "Invalid GoPro prefix '\(p)'. Must be 'GH' or 'GX'."
        case .invalidChapter(let c):
            return "Invalid chapter \(c). Must be in range 1-99."
        case .invalidFileNumber(let n):
            return "Invalid file number \(n). Must be in range 1-9999."
        }
    }
}
