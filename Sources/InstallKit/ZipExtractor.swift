import Foundation
import VouchBoxCore

public enum ZipExtractor {
    public static func extract(zip: URL, to dest: URL) async throws {
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        proc.arguments = ["-x", "-k", zip.path, dest.path]
        let err = Pipe()
        proc.standardError = err
        try proc.run()
        proc.waitUntilExit()
        guard proc.terminationStatus == 0 else {
            let stderr = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw VouchBoxError.zipExtractionFailed(stderr: stderr)
        }
    }

    /// Locate the single .app inside an extracted directory.
    public static func findAppBundle(in dir: URL) throws -> URL {
        let items = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        let apps = items.filter { $0.pathExtension == "app" }
        guard apps.count == 1, let only = apps.first else {
            throw VouchBoxError.fileSystem("expected exactly one .app at \(dir.path), found \(apps.count)")
        }
        return only
    }
}
