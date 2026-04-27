import ArgumentParser
import Foundation
import InstallKit

struct InstallCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "install",
        abstract: "Install an app from a manifest URL."
    )

    @Argument(help: "Manifest URL (HTTPS).") var manifestURL: String
    @Option(help: "Channel (default: stable).") var channel: String = "stable"
    @Flag(help: "Require manifest to be signed.") var requireSigned: Bool = false

    func run() async throws {
        guard let url = URL(string: manifestURL), url.scheme == "https" else {
            throw ValidationError("manifest URL must be HTTPS")
        }
        let coord = InstallCoordinator()
        let installed = try await coord.installOrUpdate(
            manifestURL: url,
            channel: channel,
            requireSigned: requireSigned
        ) { p in
            print("[\(p.phase.rawValue)] \(p.detail)")
        }
        print("✓ installed \(installed.version) at \(installed.installPath.path)")
    }
}
