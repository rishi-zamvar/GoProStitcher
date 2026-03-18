import Foundation

/// Errors thrown by AudioExtractor.
public enum AudioExtractorError: Error, LocalizedError, Equatable {
    /// ffmpeg binary is not present at any of the searched paths.
    case ffmpegNotFound
    /// The input file does not exist at the given URL.
    case inputNotFound(URL)
    /// ffmpeg exited with a non-zero status.
    case extractionFailed(String)
    /// The output file could not be written.
    case outputWriteFailed(String)

    public var errorDescription: String? {
        switch self {
        case .ffmpegNotFound:
            return "ffmpeg not found. Install with: brew install ffmpeg"
        case .inputNotFound(let url):
            return "Input file does not exist: \(url.path)"
        case .extractionFailed(let msg):
            return "ffmpeg extraction failed: \(msg)"
        case .outputWriteFailed(let msg):
            return "Failed to write output file: \(msg)"
        }
    }
}
