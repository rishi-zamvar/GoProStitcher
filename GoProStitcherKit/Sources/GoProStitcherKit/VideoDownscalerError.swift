import Foundation

/// Errors thrown by VideoDownscaler.
public enum VideoDownscalerError: Error, LocalizedError, Equatable {
    /// ffmpeg binary is not present at any of the searched paths.
    case ffmpegNotFound
    /// The input file does not exist at the given URL.
    case inputNotFound(URL)
    /// Source video is already at 1080p or lower — downscaling would increase file size.
    case alreadyAtTargetResolution
    /// ffmpeg exited with a non-zero status.
    case encodingFailed(String)
    /// The output file could not be written.
    case outputWriteFailed(String)

    public var errorDescription: String? {
        switch self {
        case .ffmpegNotFound:
            return "ffmpeg not found. Install with: brew install ffmpeg"
        case .inputNotFound(let url):
            return "Input file does not exist: \(url.path)"
        case .alreadyAtTargetResolution:
            return "Source video is already 1080p or lower — downscaling would increase file size"
        case .encodingFailed(let msg):
            return "ffmpeg encoding failed: \(msg)"
        case .outputWriteFailed(let msg):
            return "Failed to write output file: \(msg)"
        }
    }
}
