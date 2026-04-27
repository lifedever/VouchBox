import Foundation

public struct AppState: Codable, Sendable {
    public var installedApps: [String: InstalledApp]

    public init(installedApps: [String: InstalledApp] = [:]) {
        self.installedApps = installedApps
    }

    public static var defaultURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport
            .appendingPathComponent("com.lifedever.vouchbox")
            .appendingPathComponent("state.json")
    }

    public static func load(from url: URL = defaultURL) throws -> AppState {
        guard FileManager.default.fileExists(atPath: url.path) else { return AppState() }
        let data = try Data(contentsOf: url)
        return try JSONDecoder.vouchbox.decode(AppState.self, from: data)
    }

    public func save(to url: URL = defaultURL) throws {
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try JSONEncoder.vouchbox.encode(self)
        try data.write(to: url, options: .atomic)
    }
}

public struct InstalledApp: Codable, Sendable, Equatable {
    public let version: String
    public let installPath: URL
    public let installedAt: Date
    public let managedSince: Date

    public init(version: String, installPath: URL, installedAt: Date, managedSince: Date) {
        self.version = version
        self.installPath = installPath
        self.installedAt = installedAt
        self.managedSince = managedSince
    }
}
