import Testing
import Foundation
import CryptoKit
@testable import InstallKit

@Test func detectsValidHash() throws {
    let data = "hello".data(using: .utf8)!
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("vbtest-hash-\(UUID().uuidString)")
    try data.write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }
    let expected = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    #expect(throws: Never.self) {
        try SHA256Verifier.verify(file: url, expected: expected)
    }
}

@Test func detectsHashMismatch() throws {
    let data = "hello".data(using: .utf8)!
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("vbtest-hash-\(UUID().uuidString)")
    try data.write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }
    #expect(throws: Error.self) {
        try SHA256Verifier.verify(file: url, expected: "deadbeef")
    }
}
