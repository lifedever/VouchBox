import Foundation

public struct Manifest: Codable, Sendable, Equatable {
    public let schemaVersion: Int
    public let id: String
    public let name: String
    public let publisher: Publisher
    public let tagline: String
    public let description: String
    public let category: Category
    public let homepage: URL
    public let icon: IconRef
    public let screenshots: [Screenshot]?
    public let license: String?
    public let sourceURL: URL?
    public let privacyPolicyURL: URL?
    public let supportURL: URL?
    public let latest: Release
    public let history: [Release]?
    public let permissions: [Permission]?
    public let vouchbox: VouchBoxIntegration
    public let signature: String?

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decode(Int.self, forKey: .schemaVersion)
        guard schemaVersion == 1 else {
            throw DecodingError.dataCorruptedError(
                forKey: .schemaVersion, in: c,
                debugDescription: "unsupported schemaVersion: \(schemaVersion)"
            )
        }
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        publisher = try c.decode(Publisher.self, forKey: .publisher)
        tagline = try c.decode(String.self, forKey: .tagline)
        description = try c.decode(String.self, forKey: .description)
        category = try c.decode(Category.self, forKey: .category)
        homepage = try c.decode(URL.self, forKey: .homepage)
        icon = try c.decode(IconRef.self, forKey: .icon)
        screenshots = try c.decodeIfPresent([Screenshot].self, forKey: .screenshots)
        license = try c.decodeIfPresent(String.self, forKey: .license)
        sourceURL = try c.decodeIfPresent(URL.self, forKey: .sourceURL)
        privacyPolicyURL = try c.decodeIfPresent(URL.self, forKey: .privacyPolicyURL)
        supportURL = try c.decodeIfPresent(URL.self, forKey: .supportURL)
        latest = try c.decode(Release.self, forKey: .latest)
        history = try c.decodeIfPresent([Release].self, forKey: .history)
        permissions = try c.decodeIfPresent([Permission].self, forKey: .permissions)
        vouchbox = try c.decode(VouchBoxIntegration.self, forKey: .vouchbox)
        signature = try c.decodeIfPresent(String.self, forKey: .signature)
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, id, name, publisher, tagline, description, category, homepage
        case icon, screenshots, license, sourceURL, privacyPolicyURL, supportURL
        case latest, history, permissions, vouchbox, signature
    }
}

public struct Publisher: Codable, Sendable, Equatable {
    public let name: String
    public let url: URL
    public let email: String?
    public let publicKey: String?
}

public struct IconRef: Codable, Sendable, Equatable {
    public let url: URL
    public let sha256: String?
}

public struct Screenshot: Codable, Sendable, Equatable {
    public let url: URL
    public let caption: String?
    public let sha256: String?
}

public enum Category: String, Codable, Sendable {
    case productivity, developer, utilities, creativity, media, social, education, entertainment, other
}

public struct Release: Codable, Sendable, Equatable {
    public let version: String
    public let minOSVersion: String?
    public let publishedAt: Date
    public let releaseNotes: String?
    public let channels: [String: Channel]
}

public struct Channel: Codable, Sendable, Equatable {
    public let url: URL
    public let sha256: String
    public let size: Int64
    public let arch: Architecture
}

public enum Architecture: String, Codable, Sendable {
    case universal, arm64, x86_64
}

public struct Permission: Codable, Sendable, Equatable {
    public let type: String
    public let reason: String
}

public struct VouchBoxIntegration: Codable, Sendable, Equatable {
    public let managedFlag: String
    public let uninstallExtras: [String]?
}

extension JSONDecoder {
    public static var vouchbox: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}

extension JSONEncoder {
    public static var vouchbox: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return e
    }
}
