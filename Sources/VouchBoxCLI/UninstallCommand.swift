import ArgumentParser
import Foundation
import InstallKit

struct UninstallCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "uninstall",
        abstract: "Uninstall an app by bundle ID."
    )

    @Argument(help: "Bundle identifier.") var bundleID: String

    func run() async throws {
        let coord = InstallCoordinator()
        try await coord.uninstall(bundleID: bundleID)
        print("✓ uninstalled \(bundleID)")
        print("note: TCC permission residue must be removed manually in System Settings → Privacy & Security.")
    }
}
