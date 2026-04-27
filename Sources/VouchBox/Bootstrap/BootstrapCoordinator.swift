import Foundation
import Observation
import InstallKit
import AppKit

@Observable @MainActor
public final class BootstrapCoordinator {
    public enum State: Equatable {
        case unknown
        case alreadyStable
        case needsBootstrap
        case bootstrapping
        case error(String)
    }

    public private(set) var state: State = .unknown
    private let helperClient = HelperClient()
    private let bundleID = "com.lifedever.vouchbox"

    public init() {}

    public func checkAtLaunch() async {
        let result = await SelfSignatureChecker.classifySelf()
        switch result {
        case .stable: state = .alreadyStable
        case .needsBootstrap: state = .needsBootstrap
        case .error(let s): state = .error(s)
        }
    }

    /// Trigger helper to re-sign self in place, then schedule a relaunch and quit.
    public func executeBootstrap() async {
        state = .bootstrapping
        let bundlePath = Bundle.main.bundlePath
        do {
            try await helperClient.resignInPlace(path: bundlePath, bundleID: bundleID)
            scheduleRelaunch(bundlePath: bundlePath)
            NSApplication.shared.terminate(nil)
        } catch {
            state = .error(String(describing: error))
        }
    }

    /// Spawn a detached `open` after a short delay so launchd treats the new launch as fresh.
    private func scheduleRelaunch(bundlePath: String) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/sh")
        proc.arguments = ["-c", "sleep 1 && open \"\(bundlePath)\""]
        try? proc.run()
    }
}
