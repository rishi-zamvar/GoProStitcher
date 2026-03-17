import Foundation

/// A parsed representation of a single GoPro video file chunk.
///
/// GoPro cameras split long recordings into sequential chapters.
/// Each file follows the naming convention: {prefix}{chapter:02d}{fileNumber:04d}.MP4
///
/// Example: GH010001.MP4 → prefix="GH", chapter=1, fileNumber=1
public struct GoProChunk: Equatable, Hashable {
    /// Camera prefix — "GH" (H.264) or "GX" (HEVC/H.265).
    public let prefix: String
    /// Chapter index within the recording session (01–99).
    public let chapter: Int
    /// Recording session number (0001–9999).
    public let fileNumber: Int

    public init(prefix: String, chapter: Int, fileNumber: Int) {
        self.prefix = prefix
        self.chapter = chapter
        self.fileNumber = fileNumber
    }

    /// Reconstructed original filename for this chunk.
    public var filename: String {
        String(format: "%@%02d%04d.MP4", prefix, chapter, fileNumber)
    }
}

/// Pure parser for GoPro video filenames.
///
/// Converts a filename string into a typed ``GoProChunk`` value and
/// provides a canonical stitch order for a collection of chunks.
public enum GoProNameParser {

    // Pattern: ^(GH|GX)(\d{2})(\d{4})\.MP4$
    // Group 1: prefix (GH or GX)
    // Group 2: chapter (2 digits)
    // Group 3: fileNumber (4 digits)
    private static let regex: NSRegularExpression = {
        // Force-unwrap is safe: pattern is a compile-time constant known to be valid.
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: #"^(GH|GX)(\d{2})(\d{4})\.MP4$"#)
    }()

    /// Parses a GoPro filename into a ``GoProChunk``.
    ///
    /// - Parameter filename: The bare filename (not a full path). Case-sensitive.
    /// - Returns: A ``GoProChunk`` if the filename matches the GoPro naming convention, otherwise `nil`.
    public static func parse(_ filename: String) -> GoProChunk? {
        let range = NSRange(filename.startIndex..., in: filename)
        guard let match = regex.firstMatch(in: filename, range: range),
              match.numberOfRanges == 4 else { return nil }

        guard
            let prefixRange  = Range(match.range(at: 1), in: filename),
            let chapterRange = Range(match.range(at: 2), in: filename),
            let fileNumRange = Range(match.range(at: 3), in: filename),
            let chapter      = Int(filename[chapterRange]),
            let fileNumber   = Int(filename[fileNumRange])
        else { return nil }

        return GoProChunk(prefix: String(filename[prefixRange]), chapter: chapter, fileNumber: fileNumber)
    }

    /// Returns `chunks` sorted into canonical stitch order.
    ///
    /// Sort key: fileNumber ascending (recording session), then chapter ascending (within session).
    public static func sortedChunks(_ chunks: [GoProChunk]) -> [GoProChunk] {
        chunks.sorted {
            if $0.fileNumber != $1.fileNumber { return $0.fileNumber < $1.fileNumber }
            return $0.chapter < $1.chapter
        }
    }
}
