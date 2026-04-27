import Foundation
import VouchBoxCore
import ManifestKit
import SignKit

public struct InstallProgress: Sendable {
    public enum Phase: String, Sendable {
        case fetchingManifest, verifyingManifest, downloading, verifyingHash, extracting, helperInstall, finalizing
    }
    public let phase: Phase
    public let detail: String
}

public actor InstallCoordinator {
    private let fetcher: ManifestFetcher
    private let downloader: Downloader
    private let helperClient: HelperClient
    private let stateURL: URL

    public init(
        fetcher: ManifestFetcher = ManifestFetcher(),
        downloader: Downloader = Downloader(),
        helperClient: HelperClient = HelperClient(),
        stateURL: URL = AppState.defaultURL
    ) {
        self.fetcher = fetcher
        self.downloader = downloader
        self.helperClient = helperClient
        self.stateURL = stateURL
    }

    /// Install or update an app from its manifest URL.
    /// `requireSigned`: if true, an unsigned manifest is rejected (used for built-in catalog entries).
    public func installOrUpdate(
        manifestURL: URL,
        channel: String = "stable",
        requireSigned: Bool = false,
        progress: ((InstallProgress) -> Void)? = nil
    ) async throws -> InstalledApp {
        progress?(InstallProgress(phase: .fetchingManifest, detail: manifestURL.absoluteString))
        let (manifest, _, outcome) = try await fetcher.fetch(manifestURL)

        progress?(InstallProgress(phase: .verifyingManifest, detail: String(describing: outcome)))
        switch outcome {
        case .invalid:
            throw VouchBoxError.manifestSignatureInvalid(manifestURL)
        case .unsigned where requireSigned:
            throw VouchBoxError.manifestSignatureInvalid(manifestURL)
        default:
            break
        }

        guard let ch = manifest.latest.channels[channel] else {
            throw VouchBoxError.fileSystem("manifest has no channel: \(channel)")
        }

        let workDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("vouchbox-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: workDir) }

        let zipPath = workDir.appendingPathComponent("download.zip")
        progress?(InstallProgress(phase: .downloading, detail: ch.url.absoluteString))
        try await downloader.download(from: ch.url, to: zipPath)

        progress?(InstallProgress(phase: .verifyingHash, detail: ch.sha256))
        try SHA256Verifier.verify(file: zipPath, expected: ch.sha256)

        progress?(InstallProgress(phase: .extracting, detail: zipPath.lastPathComponent))
        let extractDir = workDir.appendingPathComponent("extracted")
        try await ZipExtractor.extract(zip: zipPath, to: extractDir)
        let appBundle = try ZipExtractor.findAppBundle(in: extractDir)

        let destPath = "/Applications/\(appBundle.lastPathComponent)"
        progress?(InstallProgress(phase: .helperInstall, detail: destPath))
        try await helperClient.install(
            extractedBundlePath: appBundle.path,
            bundleID: manifest.id,
            destPath: destPath,
            vbManagedKey: manifest.vouchbox.managedFlag
        )

        progress?(InstallProgress(phase: .finalizing, detail: manifest.id))
        var state = (try? AppState.load(from: stateURL)) ?? AppState()
        let now = Date()
        let prevManagedSince = state.installedApps[manifest.id]?.managedSince ?? now
        let installed = InstalledApp(
            version: manifest.latest.version,
            installPath: URL(fileURLWithPath: destPath),
            installedAt: now,
            managedSince: prevManagedSince
        )
        state.installedApps[manifest.id] = installed
        try state.save(to: stateURL)
        return installed
    }

    public func uninstall(bundleID: String) async throws {
        let state = (try? AppState.load(from: stateURL)) ?? AppState()
        guard let installed = state.installedApps[bundleID] else {
            throw VouchBoxError.fileSystem("not installed: \(bundleID)")
        }
        try await helperClient.uninstall(path: installed.installPath.path)
        var newState = state
        newState.installedApps.removeValue(forKey: bundleID)
        try newState.save(to: stateURL)
    }

    public func list() throws -> [String: InstalledApp] {
        let state = (try? AppState.load(from: stateURL)) ?? AppState()
        return state.installedApps
    }
}
