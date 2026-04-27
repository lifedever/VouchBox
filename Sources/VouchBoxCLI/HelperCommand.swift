import ArgumentParser
import Foundation
import InstallKit

struct HelperCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "helper",
        abstract: "Manage the privileged helper daemon.",
        subcommands: [Status.self, Install.self, Uninstall.self, Ping.self]
    )

    struct Status: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Print helper registration status.")
        func run() async throws {
            let mgr = HelperManager()
            let s = await mgr.status()
            print("helper status: \(s)")
        }
    }

    struct Install: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Register helper (will prompt for password).")
        func run() async throws {
            let mgr = HelperManager()
            try await mgr.register()
            let s = await mgr.status()
            print("registered. status: \(s)")
            if s == .requiresApproval {
                print("→ open System Settings → Login Items & Extensions → Allow VouchBox helper")
                await mgr.openApprovalSettings()
            }
        }
    }

    struct Uninstall: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Unregister helper.")
        func run() async throws {
            let mgr = HelperManager()
            try await mgr.unregister()
            print("unregistered.")
        }
    }

    struct Ping: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Ping helper, print version.")
        func run() async throws {
            let client = HelperClient()
            let version = try await client.ping()
            print("helper version: \(version)")
        }
    }
}
