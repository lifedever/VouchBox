import Testing
import Foundation
@testable import VouchBox

@Test func detectsStableDR() async throws {
    let result = await SelfSignatureChecker.classify(forBundleAtPath: "/System/Applications/Calculator.app")
    if case .stable = result { /* ok */ }
    else { Issue.record("Calculator.app should classify as stable, got \(result)") }
}

@Test func reportsErrorForMissingPath() async throws {
    let result = await SelfSignatureChecker.classify(forBundleAtPath: "/tmp/does-not-exist-\(UUID().uuidString).app")
    if case .error = result { /* ok */ }
    else { Issue.record("expected .error, got \(result)") }
}
