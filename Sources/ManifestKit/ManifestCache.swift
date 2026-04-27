import Foundation
import CryptoKit

public struct CachedManifest: Sendable {
    public let rawData: Data
    public let fetchedAt: Date
}

public struct ManifestCache: Sendable {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.init(directory: appSupport
            .appendingPathComponent("com.lifedever.vouchbox")
            .appendingPathComponent("manifest-cache"))
    }

    public func store(rawData: Data, for url: URL, fetchedAt: Date) throws {
        let key = Self.cacheKey(for: url)
        let payload = try JSONEncoder().encode(CachedPayload(
            rawDataBase64: rawData.base64EncodedString(),
            fetchedAt: fetchedAt
        ))
        try payload.write(to: directory.appendingPathComponent(key), options: .atomic)
    }

    public func load(for url: URL) -> CachedManifest? {
        let key = Self.cacheKey(for: url)
        guard let data = try? Data(contentsOf: directory.appendingPathComponent(key)),
              let payload = try? JSONDecoder().decode(CachedPayload.self, from: data),
              let raw = Data(base64Encoded: payload.rawDataBase64)
        else { return nil }
        return CachedManifest(rawData: raw, fetchedAt: payload.fetchedAt)
    }

    private static func cacheKey(for url: URL) -> String {
        let h = SHA256.hash(data: url.absoluteString.data(using: .utf8)!)
        return h.map { String(format: "%02x", $0) }.joined() + ".json"
    }

    private struct CachedPayload: Codable {
        let rawDataBase64: String
        let fetchedAt: Date
    }
}
