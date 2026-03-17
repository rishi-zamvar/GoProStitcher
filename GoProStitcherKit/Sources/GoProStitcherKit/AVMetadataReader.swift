import AVFoundation
import AppKit
import Foundation

/// A pure static namespace for extracting metadata from local MP4 files using AVFoundation async APIs.
///
/// Usage:
/// ```swift
/// let dur = await AVMetadataReader.duration(url: fileURL)
/// let size = await AVMetadataReader.resolution(url: fileURL)
/// let img  = await AVMetadataReader.thumbnail(url: fileURL)
/// ```
public enum AVMetadataReader {

    /// Returns the duration (in seconds) of the MP4 at `url`, or `nil` if unreadable.
    ///
    /// Uses `AVURLAsset` and the async `load(.duration)` API (macOS 13+).
    /// Returns `nil` for non-existent files, invalid assets, zero-duration, or indefinite duration.
    public static func duration(url: URL) async -> TimeInterval? {
        let asset = AVURLAsset(url: url)
        guard let cmDuration = try? await asset.load(.duration) else { return nil }
        guard cmDuration.isValid, !cmDuration.isIndefinite else { return nil }
        let seconds = cmDuration.seconds
        guard seconds > 0 else { return nil }
        return seconds
    }

    /// Returns the resolution (natural size) of the first video track in the MP4 at `url`,
    /// or `nil` if the asset cannot be loaded or has no video track.
    public static func resolution(url: URL) async -> CGSize? {
        let asset = AVURLAsset(url: url)
        guard let tracks = try? await asset.loadTracks(withMediaType: .video),
              let track = tracks.first else { return nil }
        guard let naturalSize = try? await track.load(.naturalSize) else { return nil }
        guard naturalSize.width > 0, naturalSize.height > 0 else { return nil }
        return naturalSize
    }

    /// Returns an `NSImage` of the first frame of the MP4 at `url`,
    /// or `nil` if the asset cannot be loaded or frame extraction fails.
    ///
    /// Uses `AVAssetImageGenerator` with `appliesPreferredTrackTransform = true`.
    public static func thumbnail(url: URL) async -> NSImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = CMTime(seconds: 1, preferredTimescale: 600)

        // Use the new async API (macOS 13+); fall back to synchronous if needed.
        if #available(macOS 13, *) {
            guard let result = try? await generator.image(at: .zero) else { return nil }
            return NSImage(cgImage: result.image, size: .zero)
        } else {
            guard let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) else {
                return nil
            }
            return NSImage(cgImage: cgImage, size: .zero)
        }
    }
}
