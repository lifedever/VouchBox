import Foundation

public let helperMachServiceName = "com.lifedever.vouchbox.helper"

@objc public protocol VouchBoxHelperProtocol {
    /// Liveness check — returns helper version string.
    func ping(reply: @escaping (String) -> Void)

    /// Install/update an app:
    /// - extractedBundlePath: temp .app already extracted from .zip
    /// - bundleID: expected bundle identifier (verified against Info.plist)
    /// - destPath: target absolute path (typically /Applications/<App>.app)
    /// - vbManagedKey: Info.plist key to inject (typically "VBManaged")
    /// On success replies with nil error; on failure replies with non-nil error.
    func install(
        extractedBundlePath: String,
        bundleID: String,
        destPath: String,
        vbManagedKey: String,
        reply: @escaping (Error?) -> Void
    )

    /// Uninstall: remove .app at path. (TCC residue must be handled by user via System Settings.)
    func uninstall(path: String, reply: @escaping (Error?) -> Void)

    /// Re-sign an existing bundle in place (used for VouchBox self-bootstrap).
    func resignInPlace(
        path: String,
        bundleID: String,
        reply: @escaping (Error?) -> Void
    )
}
