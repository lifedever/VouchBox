import Foundation

public enum SignatureClassification: Sendable, Equatable {
    case stable(bundleID: String)
    case cdhashOnly
    case unsigned
    case other(String)
}

public enum SignatureInspector {
    public static func classify(designatedRequirement dr: String) -> SignatureClassification {
        let trimmed = dr.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return .unsigned }
        if let id = DesignatedRequirement.parseIdentifier(from: trimmed) {
            return .stable(bundleID: id)
        }
        if trimmed.contains("cdhash") {
            return .cdhashOnly
        }
        return .other(trimmed)
    }

    public static func isStableForBundleID(_ bundleID: String, dr: String) -> Bool {
        if case .stable(let id) = classify(designatedRequirement: dr) {
            return id == bundleID
        }
        return false
    }
}
