import Foundation
import ServiceManagement
import VouchBoxCore

public enum HelperStatus: Sendable, Equatable {
    case notRegistered
    case requiresApproval
    case enabled
    case unknown(Int)

    public init(_ raw: SMAppService.Status) {
        switch raw {
        case .notRegistered: self = .notRegistered
        case .requiresApproval: self = .requiresApproval
        case .enabled: self = .enabled
        case .notFound: self = .unknown(raw.rawValue)
        @unknown default: self = .unknown(raw.rawValue)
        }
    }
}

public actor HelperManager {
    public static let plistName = "com.lifedever.vouchbox.helper.plist"

    private var service: SMAppService {
        SMAppService.daemon(plistName: Self.plistName)
    }

    public init() {}

    public func status() -> HelperStatus {
        HelperStatus(service.status)
    }

    /// Register helper. Triggers password prompt if not already enabled.
    public func register() throws {
        do {
            try service.register()
        } catch {
            throw VouchBoxError.helperRegistrationFailed(reason: error.localizedDescription)
        }
    }

    public func unregister() async throws {
        do {
            try await service.unregister()
        } catch {
            throw VouchBoxError.helperRegistrationFailed(reason: error.localizedDescription)
        }
    }

    /// Open System Settings to the Login Items > Background pane (where user approves daemon).
    public func openApprovalSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
