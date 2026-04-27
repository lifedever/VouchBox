import Testing
@testable import SignKit

@Test func generatesStableDR() {
    let dr = DesignatedRequirement.stable(forBundleID: "com.example.app")
    #expect(dr == #"=designated => identifier "com.example.app""#)
}

@Test func parsesIdentifierFromDR() {
    let parsed = DesignatedRequirement.parseIdentifier(
        from: #"designated => identifier "com.example.app""#
    )
    #expect(parsed == "com.example.app")
}

@Test func parsesNilFromCdhashDR() {
    let parsed = DesignatedRequirement.parseIdentifier(
        from: #"designated => cdhash H"abcdef0123456789""#
    )
    #expect(parsed == nil)
}
