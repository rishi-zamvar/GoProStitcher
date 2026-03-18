import Foundation

/// Encoding progress reported by VideoDownscaler during a downscale operation.
public struct DownscaleProgress {
    /// Normalised progress in the range 0.0 – 1.0.
    public let fraction: Double
    /// Seconds of video that have been encoded so far.
    public let secondsProcessed: Double
    /// Total duration of the source file in seconds.
    public let totalSeconds: Double
    /// Current output bitrate in kilobits per second.
    public let bitrateKbps: Double
    /// Current encoding speed in frames per second.
    public let fps: Double

    public init(
        fraction: Double,
        secondsProcessed: Double,
        totalSeconds: Double,
        bitrateKbps: Double,
        fps: Double
    ) {
        self.fraction = fraction
        self.secondsProcessed = secondsProcessed
        self.totalSeconds = totalSeconds
        self.bitrateKbps = bitrateKbps
        self.fps = fps
    }
}
