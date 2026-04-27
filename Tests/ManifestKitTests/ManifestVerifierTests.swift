import Testing
import Foundation
import CryptoKit
@testable import ManifestKit
@testable import VouchBoxCore

@Test func acceptsValidSignature() throws {
    let key = Curve25519.Signing.PrivateKey()
    let pubKeyB64 = key.publicKey.rawRepresentation.base64EncodedString()

    // build a manifest dict (without signature), serialize canonically, sign
    let payloadDict: [String: Any] = [
        "schemaVersion": 1,
        "id": "com.example.app",
        "publisher": ["name": "X", "url": "https://x.com", "publicKey": pubKeyB64]
    ]
    let canonical = try CanonicalJSON.encode(payloadDict)
    let signature = try key.signature(for: canonical).base64EncodedString()

    var withSig = payloadDict
    withSig["signature"] = signature

    let result = try ManifestVerifier.verify(
        canonicalPayload: canonical,
        signatureBase64: signature,
        publicKeyBase64: pubKeyB64
    )
    #expect(result == true)
}

@Test func rejectsBadSignature() throws {
    let key = Curve25519.Signing.PrivateKey()
    let pubKeyB64 = key.publicKey.rawRepresentation.base64EncodedString()
    let canonical = "{}".data(using: .utf8)!
    let bogusSig = Data(repeating: 0, count: 64).base64EncodedString()

    let result = try ManifestVerifier.verify(
        canonicalPayload: canonical,
        signatureBase64: bogusSig,
        publicKeyBase64: pubKeyB64
    )
    #expect(result == false)
}

@Test func verifiesFullSignedManifestRaw() throws {
    let key = Curve25519.Signing.PrivateKey()
    let pubKeyB64 = key.publicKey.rawRepresentation.base64EncodedString()
    let payload: [String: Any] = [
        "schemaVersion": 1,
        "id": "com.example.app",
        "publisher": ["name": "X", "url": "https://x.com", "publicKey": pubKeyB64]
    ]
    let canonical = try CanonicalJSON.encode(payload)
    let sig = try key.signature(for: canonical).base64EncodedString()
    var full = payload
    full["signature"] = sig
    let raw = try CanonicalJSON.encode(full)

    let outcome = try ManifestVerifier.verifyRawManifest(raw)
    if case .verified = outcome { /* ok */ } else { Issue.record("expected .verified, got \(outcome)") }
}

@Test func detectsUnsignedManifest() throws {
    let raw = #"{"schemaVersion":1,"id":"x"}"#.data(using: .utf8)!
    let outcome = try ManifestVerifier.verifyRawManifest(raw)
    #expect(outcome == .unsigned)
}
