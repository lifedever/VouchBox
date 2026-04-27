import ArgumentParser
import Foundation
import InstallKit

struct ListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List apps installed via VouchBox."
    )

    func run() async throws {
        let coord = InstallCoordinator()
        let map = try await coord.list()
        if map.isEmpty {
            print("(no apps installed via VouchBox)")
            return
        }
        for (id, app) in map.sorted(by: { $0.key < $1.key }) {
            print("\(id)  \(app.version)  \(app.installPath.path)")
        }
    }
}
