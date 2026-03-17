import Foundation

/// Describes the current phase of the stitch pipeline.
public enum StitchPhase: Equatable {
    /// Saving the manifest file (records chunk boundaries for reversion).
    case savingManifest
    /// Stitching is in progress; indicates which source file (by index) is being appended.
    case stitching(fileIndex: Int, fileName: String)
    /// Pipeline completed successfully.
    case complete
    /// Pipeline failed with a human-readable message.
    case failed(String)
}
