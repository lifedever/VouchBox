import ArgumentParser
import Foundation

@main
struct VouchBox: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "vouchbox",
        abstract: "Local distribution manager for indie macOS apps without Developer ID.",
        subcommands: [
            InstallCommand.self,
            UpdateCommand.self,
            UninstallCommand.self,
            ListCommand.self,
            HelperCommand.self,
            SignManifestCommand.self,
        ]
    )
}
