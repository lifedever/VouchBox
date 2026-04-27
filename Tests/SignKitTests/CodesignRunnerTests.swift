import Testing
import Foundation
@testable import SignKit

@Test func runsCodesignSuccessfullyOnRealApp() async throws {
    // Use /System/Applications/Calculator.app for read-only inspection (don't modify system!)
    // We'll only test the inspect path here. Modifying tests need a fixture.
    let runner = CodesignRunner()
    let info = try await runner.inspect(URL(fileURLWithPath: "/System/Applications/Calculator.app"))
    #expect(info.identifier.contains("Calculator") || info.identifier.contains("calculator"))
}

@Test func reportsCodesignFailureOnMissingPath() async {
    let runner = CodesignRunner()
    await #expect(throws: Error.self) {
        try await runner.inspect(URL(fileURLWithPath: "/tmp/does-not-exist.app"))
    }
}
