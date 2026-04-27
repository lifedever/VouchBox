import Testing
import Foundation
@testable import VouchBoxCore

@Suite("Manifest decoding")
struct ManifestTests {
    @Test func decodesMinimalManifest() throws {
        let json = """
        {
          "schemaVersion": 1,
          "id": "com.example.app",
          "name": "Example",
          "publisher": { "name": "Example Inc.", "url": "https://example.com" },
          "tagline": "demo",
          "description": "desc",
          "category": "utilities",
          "homepage": "https://example.com",
          "icon": { "url": "https://example.com/icon.png" },
          "latest": {
            "version": "1.0.0",
            "publishedAt": "2026-04-27T10:00:00Z",
            "channels": {
              "stable": {
                "url": "https://example.com/app-1.0.0.zip",
                "sha256": "abc123",
                "size": 1024,
                "arch": "universal"
              }
            }
          },
          "vouchbox": { "managedFlag": "VBManaged" }
        }
        """.data(using: .utf8)!

        let m = try JSONDecoder.vouchbox.decode(Manifest.self, from: json)
        #expect(m.id == "com.example.app")
        #expect(m.latest.version == "1.0.0")
        #expect(m.latest.channels["stable"]?.sha256 == "abc123")
    }

    @Test func rejectsWrongSchemaVersion() throws {
        let json = #"{"schemaVersion": 99, "id": "x"}"#.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder.vouchbox.decode(Manifest.self, from: json)
        }
    }
}
