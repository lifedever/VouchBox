import Testing
import Foundation
@testable import SignKit

@Test func detectsStableDR() async throws {
    // can't easily fake a real .app here, so we test the pure parser path
    let result = SignatureInspector.classify(
        designatedRequirement: #"designated => identifier "com.example.app""#
    )
    #expect(result == .stable(bundleID: "com.example.app"))
}

@Test func detectsCdhashDR() async throws {
    let result = SignatureInspector.classify(
        designatedRequirement: #"designated => cdhash H"abc""#
    )
    #expect(result == .cdhashOnly)
}

@Test func detectsAdhocUnsigned() async throws {
    let result = SignatureInspector.classify(designatedRequirement: "")
    #expect(result == .unsigned)
}
