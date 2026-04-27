import Foundation
import VouchBoxCore

public actor ManifestFetcher {
    private let session: URLSession
    private let cache: ManifestCache

    public init(session: URLSession = .shared, cache: ManifestCache = ManifestCache()) {
        self.session = session
        self.cache = cache
    }

    public func fetch(_ url: URL, useCache: Bool = true) async throws -> (Manifest, Data, VerificationOutcome) {
        guard url.scheme == "https" else {
            throw VouchBoxError.manifestParseFailed(url, underlying: NSError(domain: "VouchBox", code: 1, userInfo: [NSLocalizedDescriptionKey: "HTTP not allowed; HTTPS required"]))
        }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw VouchBoxError.downloadFailed(url, underlying: nil)
        }
        let outcome = try ManifestVerifier.verifyRawManifest(data)
        let manifest: Manifest
        do {
            manifest = try JSONDecoder.vouchbox.decode(Manifest.self, from: data)
        } catch {
            throw VouchBoxError.manifestParseFailed(url, underlying: error)
        }
        try cache.store(rawData: data, for: url, fetchedAt: Date())
        return (manifest, data, outcome)
    }

    public func cached(_ url: URL) -> CachedManifest? {
        cache.load(for: url)
    }
}
