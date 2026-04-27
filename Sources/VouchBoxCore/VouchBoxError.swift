import Foundation

public enum VouchBoxError: Error, CustomStringConvertible {
    case sha256Mismatch(expected: String, actual: String)
    case downloadFailed(URL, underlying: Error?)
    case manifestParseFailed(URL, underlying: Error)
    case manifestSignatureInvalid(URL)
    case manifestSignatureMissingPublicKey
    case codesignFailed(stderr: String)
    case helperUnavailable(reason: String)
    case helperRegistrationFailed(reason: String)
    case zipExtractionFailed(stderr: String)
    case quarantineRemovalFailed(stderr: String)
    case bundleIdentifierMismatch(expected: String, actual: String)
    case fileSystem(String)
    case unsupportedSchemaVersion(Int)

    public var description: String {
        switch self {
        case .sha256Mismatch(let e, let a): return "sha256 mismatch: expected \(e), got \(a)"
        case .downloadFailed(let u, let err): return "download failed: \(u) (\(err?.localizedDescription ?? "no underlying"))"
        case .manifestParseFailed(let u, let err): return "manifest parse failed: \(u) — \(err)"
        case .manifestSignatureInvalid(let u): return "manifest signature invalid: \(u)"
        case .manifestSignatureMissingPublicKey: return "manifest has signature but no publicKey"
        case .codesignFailed(let s): return "codesign failed: \(s)"
        case .helperUnavailable(let r): return "helper unavailable: \(r)"
        case .helperRegistrationFailed(let r): return "helper registration failed: \(r)"
        case .zipExtractionFailed(let s): return "zip extraction failed: \(s)"
        case .quarantineRemovalFailed(let s): return "quarantine removal failed: \(s)"
        case .bundleIdentifierMismatch(let e, let a): return "bundle ID mismatch: manifest says \(e), .app has \(a)"
        case .fileSystem(let s): return "filesystem error: \(s)"
        case .unsupportedSchemaVersion(let v): return "unsupported manifest schemaVersion: \(v)"
        }
    }
}
