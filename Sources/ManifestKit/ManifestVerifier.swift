import Foundation
import CryptoKit
import VouchBoxCore

public enum ManifestVerifier {
    public static func verify(
        canonicalPayload: Data,
        signatureBase64: String,
        publicKeyBase64: String
    ) throws -> Bool {
        guard let sigData = Data(base64Encoded: signatureBase64) else { return false }
        guard let keyData = Data(base64Encoded: publicKeyBase64) else { return false }
        guard let pubKey = try? Curve25519.Signing.PublicKey(rawRepresentation: keyData) else {
            return false
        }
        return pubKey.isValidSignature(sigData, for: canonicalPayload)
    }

    /// Verify a raw manifest JSON blob: extracts signature + publicKey from JSON,
    /// canonicalizes the rest, verifies.
    public static func verifyRawManifest(_ rawJSON: Data) throws -> VerificationOutcome {
        guard let dict = try JSONSerialization.jsonObject(with: rawJSON) as? [String: Any] else {
            throw VouchBoxError.manifestParseFailed(URL(fileURLWithPath: "/"), underlying: NSError(domain: "VouchBox", code: 0))
        }
        guard let signature = dict["signature"] as? String else {
            return .unsigned
        }
        guard let publisher = dict["publisher"] as? [String: Any],
              let publicKey = publisher["publicKey"] as? String else {
            throw VouchBoxError.manifestSignatureMissingPublicKey
        }
        let canonical = try CanonicalJSON.encodeForSigning(rawJSON)
        let valid = try verify(
            canonicalPayload: canonical,
            signatureBase64: signature,
            publicKeyBase64: publicKey
        )
        return valid ? .verified(publicKeyFingerprint: fingerprint(publicKey)) : .invalid
    }

    private static func fingerprint(_ pubKeyBase64: String) -> String {
        guard let data = Data(base64Encoded: pubKeyBase64) else { return "?" }
        let hash = SHA256.hash(data: data)
        return hash.prefix(8).map { String(format: "%02x", $0) }.joined()
    }
}

public enum VerificationOutcome: Sendable, Equatable {
    case verified(publicKeyFingerprint: String)
    case unsigned
    case invalid
}
