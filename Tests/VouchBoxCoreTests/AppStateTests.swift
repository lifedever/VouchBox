import Testing
import Foundation
@testable import VouchBoxCore

@Test func appStateRoundTrip() throws {
    var state = AppState()
    state.installedApps["com.example.app"] = InstalledApp(
        version: "1.0.0",
        installPath: URL(fileURLWithPath: "/Applications/Example.app"),
        installedAt: Date(timeIntervalSince1970: 100),
        managedSince: Date(timeIntervalSince1970: 100)
    )
    let data = try JSONEncoder.vouchbox.encode(state)
    let decoded = try JSONDecoder.vouchbox.decode(AppState.self, from: data)
    #expect(decoded.installedApps["com.example.app"]?.version == "1.0.0")
}
