import Foundation

public enum DesignatedRequirement {
    public static func stable(forBundleID bundleID: String) -> String {
        return #"=designated => identifier "\#(bundleID)""#
    }

    public static func parseIdentifier(from drString: String) -> String? {
        // matches: identifier "<bundle.id>"
        let pattern = #"identifier\s+"([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: drString, range: NSRange(drString.startIndex..., in: drString)),
              let range = Range(match.range(at: 1), in: drString)
        else { return nil }
        return String(drString[range])
    }
}
