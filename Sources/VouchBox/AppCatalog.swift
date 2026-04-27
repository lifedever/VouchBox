import Foundation
import Observation
import VouchBoxCore
import ManifestKit
import InstallKit

@Observable @MainActor
public final class AppCatalog {
    public private(set) var entries: [ManifestEntry] = []
    public private(set) var installed: [String: InstalledApp] = [:]
    public private(set) var refreshing = false

    private let fetcher = ManifestFetcher()
    private let coord = InstallCoordinator()

    public init() {
        rebuildEntryList()
    }

    public func rebuildEntryList() {
        let builtIn = BuiltInCatalog.lifedeverManifestURLs.map {
            ManifestEntry(manifestURL: $0, source: .builtIn)
        }
        let user = UserManifestStore.load().map {
            ManifestEntry(manifestURL: $0, source: .userAdded)
        }
        entries = builtIn + user
    }

    public func reloadInstalled() async {
        if let map = try? await coord.list() {
            installed = map
        }
    }

    public func refreshAll() async {
        refreshing = true
        defer { refreshing = false }
        await withTaskGroup(of: (URL, ManifestEntry).self) { group in
            for entry in entries {
                let f = fetcher
                group.addTask {
                    do {
                        let (m, _, outcome) = try await f.fetch(entry.manifestURL)
                        var e = entry
                        e.manifest = m
                        e.verification = outcome
                        e.lastFetchedAt = Date()
                        e.fetchError = nil
                        return (entry.manifestURL, e)
                    } catch {
                        var e = entry
                        e.fetchError = String(describing: error)
                        e.lastFetchedAt = Date()
                        return (entry.manifestURL, e)
                    }
                }
            }
            for await (_, updated) in group {
                if let idx = entries.firstIndex(where: { $0.manifestURL == updated.manifestURL }) {
                    entries[idx] = updated
                }
            }
        }
        await reloadInstalled()
    }

    public func install(_ entry: ManifestEntry, progress: @escaping @Sendable (InstallProgress) -> Void) async throws {
        let requireSigned = (entry.source == .builtIn)
        _ = try await coord.installOrUpdate(
            manifestURL: entry.manifestURL,
            requireSigned: requireSigned,
            progress: progress
        )
        await reloadInstalled()
    }

    public func uninstall(bundleID: String) async throws {
        try await coord.uninstall(bundleID: bundleID)
        await reloadInstalled()
    }

    public func addUserManifest(_ url: URL) {
        UserManifestStore.add(url)
        rebuildEntryList()
    }

    public func removeUserManifest(_ url: URL) {
        UserManifestStore.remove(url)
        rebuildEntryList()
    }

    public func installedVersion(for bundleID: String) -> String? {
        installed[bundleID]?.version
    }
}
