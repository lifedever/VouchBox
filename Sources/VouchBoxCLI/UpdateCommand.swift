import ArgumentParser
import Foundation
import InstallKit
import VouchBoxCore

struct UpdateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update an installed app to latest manifest version."
    )

    @Argument(help: "Manifest URL.") var manifestURL: String

    func run() async throws {
        guard let url = URL(string: manifestURL) else {
            throw ValidationError("invalid URL")
        }
        let coord = InstallCoordinator()
        let installed = try await coord.installOrUpdate(manifestURL: url) { p in
            print("[\(p.phase.rawValue)] \(p.detail)")
        }
        print("✓ updated to \(installed.version)")
    }
}
