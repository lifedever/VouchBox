import Testing
import Foundation
@testable import ManifestKit
@testable import VouchBoxCore

@Test func cachePersistsAndReloads() throws {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("vbtest-\(UUID().uuidString)")
    let cache = ManifestCache(directory: dir)
    let raw = #"{"id":"x"}"#.data(using: .utf8)!
    let url = URL(string: "https://example.com/m.json")!
    try cache.store(rawData: raw, for: url, fetchedAt: Date())
    let loaded = cache.load(for: url)
    #expect(loaded?.rawData == raw)
    try? FileManager.default.removeItem(at: dir)
}
