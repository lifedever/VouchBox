import Testing
import Foundation
@testable import InstallKit

@Test func extractsZip() async throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("vbtest-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tmp) }
    let payload = tmp.appendingPathComponent("payload.txt")
    try "hello".data(using: .utf8)!.write(to: payload)
    let zipURL = tmp.appendingPathComponent("test.zip")
    let zipProc = Process()
    zipProc.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
    zipProc.currentDirectoryURL = tmp
    zipProc.arguments = ["test.zip", "payload.txt"]
    try zipProc.run()
    zipProc.waitUntilExit()

    let outDir = tmp.appendingPathComponent("out")
    try await ZipExtractor.extract(zip: zipURL, to: outDir)
    let extractedFile = outDir.appendingPathComponent("payload.txt")
    #expect(FileManager.default.fileExists(atPath: extractedFile.path))
}
