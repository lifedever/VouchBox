import Foundation
import CryptoKit
import VouchBoxCore

public enum SHA256Verifier {
    public static func verify(file: URL, expected: String) throws {
        var hasher = SHA256()
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        while true {
            let chunk = handle.readData(ofLength: 1 << 20)
            if chunk.isEmpty { break }
            hasher.update(data: chunk)
        }
        let actual = hasher.finalize().map { String(format: "%02x", $0) }.joined()
        guard actual.lowercased() == expected.lowercased() else {
            throw VouchBoxError.sha256Mismatch(expected: expected, actual: actual)
        }
    }
}
