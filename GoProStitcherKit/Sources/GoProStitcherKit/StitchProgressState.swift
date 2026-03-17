import Foundation

/// Describes the current phase of the stitch + archive pipeline.
public enum StitchPhase: Equatable {
    /// Stitching is in progress; indicates which source file (by index) is being appended.
    case stitching(fileIndex: Int, fileName: String)
    /// Archiving is in progress; indicates which chunk (by index) is being zipped.
    case archiving(fileIndex: Int, fileName: String)
    /// Pipeline completed successfully.
    case complete
    /// Pipeline failed with a human-readable message.
    case failed(String)
}
