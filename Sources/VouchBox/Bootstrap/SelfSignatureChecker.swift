import Foundation
import SignKit

public enum SelfSignatureCheckResult: Sendable, Equatable {
    case stable(bundleID: String)
    case needsBootstrap
    case error(String)
}

public enum SelfSignatureChecker {
    public static func classify(forBundleAtPath path: String) async -> SelfSignatureCheckResult {
        let runner = CodesignRunner()
        do {
            let info = try await runner.inspect(URL(fileURLWithPath: path))
            switch SignatureInspector.classify(designatedRequirement: info.designatedRequirement) {
            case .stable(let id): return .stable(bundleID: id)
            case .cdhashOnly, .unsigned: return .needsBootstrap
            case .other(let s): return .error("unexpected DR: \(s)")
            }
        } catch {
            return .error(String(describing: error))
        }
    }

    public static func classifySelf() async -> SelfSignatureCheckResult {
        let bundlePath = Bundle.main.bundlePath
        return await classify(forBundleAtPath: bundlePath)
    }
}
