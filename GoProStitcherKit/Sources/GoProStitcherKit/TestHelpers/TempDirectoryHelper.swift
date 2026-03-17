import Foundation

public struct TempDirectoryHelper {
    /// Creates a uniquely-named temp directory under FileManager.default.temporaryDirectory.
    /// Caller must call cleanup(url:) in tearDown.
    public static func create() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("GoProStitcherTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Deletes the directory and all contents. Silently ignores "does not exist" errors.
    public static func cleanup(url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
