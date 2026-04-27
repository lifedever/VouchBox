import Foundation

/// Deterministic JSON serialization for signing/verification:
/// - object keys sorted ascending
/// - no whitespace
/// - escapes match JSONSerialization defaults
public enum CanonicalJSON {
    public static func encode(_ object: Any) throws -> Data {
        return try JSONSerialization.data(
            withJSONObject: object,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
    }

    /// Strip the `signature` field then canonicalize.
    public static func encodeForSigning(_ rawJSON: Data) throws -> Data {
        guard var dict = try JSONSerialization.jsonObject(with: rawJSON) as? [String: Any] else {
            throw NSError(domain: "CanonicalJSON", code: 1)
        }
        dict.removeValue(forKey: "signature")
        return try encode(dict)
    }
}
