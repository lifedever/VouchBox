import Foundation
import VouchBoxCore

public actor Downloader {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func download(from url: URL, to destination: URL, progress: ((Double) -> Void)? = nil) async throws {
        guard url.scheme == "https" else {
            throw VouchBoxError.downloadFailed(url, underlying: NSError(domain: "VouchBox", code: 2, userInfo: [NSLocalizedDescriptionKey: "HTTPS required"]))
        }
        let (tmpURL, response) = try await session.download(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw VouchBoxError.downloadFailed(url, underlying: nil)
        }
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: tmpURL, to: destination)
    }
}
