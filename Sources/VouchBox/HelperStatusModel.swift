import Foundation
import Observation
import InstallKit

@Observable @MainActor
public final class HelperStatusModel {
    public private(set) var status: HelperStatus = .notRegistered
    public private(set) var helperVersion: String?
    public private(set) var lastError: String?

    private let manager = HelperManager()
    private let client = HelperClient()

    public func refresh() async {
        status = await manager.status()
        if status == .enabled {
            do {
                helperVersion = try await client.ping()
            } catch {
                helperVersion = nil
                lastError = String(describing: error)
            }
        } else {
            helperVersion = nil
        }
    }

    public func register() async {
        do {
            try await manager.register()
            await refresh()
        } catch {
            lastError = String(describing: error)
        }
    }

    public func openApprovalSettings() async {
        await manager.openApprovalSettings()
    }
}
