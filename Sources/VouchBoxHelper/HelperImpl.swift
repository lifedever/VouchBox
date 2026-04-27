import Foundation
import HelperProtocol
import SignKit
import VouchBoxCore

final class HelperImpl: NSObject, VouchBoxHelperProtocol, @unchecked Sendable {
    static let version = "0.1.0"
    private let runner = CodesignRunner()

    func ping(reply: @escaping (String) -> Void) {
        reply(Self.version)
    }

    func install(
        extractedBundlePath: String,
        bundleID: String,
        destPath: String,
        vbManagedKey: String,
        reply: @escaping (Error?) -> Void
    ) {
        Task {
            do {
                try await performInstall(
                    extractedBundlePath: extractedBundlePath,
                    bundleID: bundleID,
                    destPath: destPath,
                    vbManagedKey: vbManagedKey
                )
                reply(nil)
            } catch {
                reply(error as NSError)
            }
        }
    }

    func uninstall(path: String, reply: @escaping (Error?) -> Void) {
        do {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            reply(nil)
        } catch {
            reply(error as NSError)
        }
    }

    func shutdown(reply: @escaping () -> Void) {
        reply()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            exit(0)
        }
    }

    func resignInPlace(path: String, bundleID: String, reply: @escaping (Error?) -> Void) {
        Task {
            do {
                let url = URL(fileURLWithPath: path)
                let dr = DesignatedRequirement.stable(forBundleID: bundleID)
                try await runner.resign(bundle: url, identifier: bundleID, designatedRequirement: dr)
                try removeQuarantine(at: url)
                reply(nil)
            } catch {
                reply(error as NSError)
            }
        }
    }

    // MARK: - private

    private func performInstall(
        extractedBundlePath: String,
        bundleID: String,
        destPath: String,
        vbManagedKey: String
    ) async throws {
        let src = URL(fileURLWithPath: extractedBundlePath)
        let dst = URL(fileURLWithPath: destPath)

        try verifyBundleID(at: src, expected: bundleID)
        try injectManagedFlag(at: src, key: vbManagedKey)
        try removeQuarantine(at: src)

        let dr = DesignatedRequirement.stable(forBundleID: bundleID)
        try await runner.resign(bundle: src, identifier: bundleID, designatedRequirement: dr)

        let backup = dst.appendingPathExtension("vbbackup-\(UUID().uuidString)")
        let fm = FileManager.default
        let hadOld = fm.fileExists(atPath: dst.path)
        if hadOld {
            try fm.moveItem(at: dst, to: backup)
        }
        do {
            try fm.moveItem(at: src, to: dst)
        } catch {
            if hadOld {
                try? fm.moveItem(at: backup, to: dst)
            }
            throw error
        }
        if hadOld {
            try? fm.removeItem(at: backup)
        }
    }

    private func verifyBundleID(at url: URL, expected: String) throws {
        let plistURL = url.appendingPathComponent("Contents/Info.plist")
        guard let data = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let actual = plist["CFBundleIdentifier"] as? String
        else {
            throw VouchBoxError.fileSystem("missing or unreadable Info.plist at \(plistURL.path)")
        }
        guard actual == expected else {
            throw VouchBoxError.bundleIdentifierMismatch(expected: expected, actual: actual)
        }
    }

    private func injectManagedFlag(at url: URL, key: String) throws {
        let plistURL = url.appendingPathComponent("Contents/Info.plist")
        guard let data = try? Data(contentsOf: plistURL),
              var plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            throw VouchBoxError.fileSystem("cannot read Info.plist at \(plistURL.path)")
        }
        plist[key] = true
        let newData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try newData.write(to: plistURL, options: .atomic)
    }

    private func removeQuarantine(at url: URL) throws {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        proc.arguments = ["-dr", "com.apple.quarantine", url.path]
        let err = Pipe()
        proc.standardError = err
        try proc.run()
        proc.waitUntilExit()
        guard proc.terminationStatus == 0 else {
            let stderr = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            if stderr.contains("No such xattr") || stderr.isEmpty { return }
            throw VouchBoxError.quarantineRemovalFailed(stderr: stderr)
        }
    }
}
