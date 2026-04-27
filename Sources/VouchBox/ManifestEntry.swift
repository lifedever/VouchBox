import Foundation
import VouchBoxCore
import ManifestKit

public enum ManifestSource: String, Codable, Sendable {
    case builtIn
    case userAdded
}

public struct ManifestEntry: Identifiable, Sendable, Equatable {
    public var id: URL { manifestURL }
    public let manifestURL: URL
    public let source: ManifestSource
    public var manifest: Manifest?
    public var verification: VerificationOutcome?
    public var lastFetchedAt: Date?
    public var fetchError: String?
}
