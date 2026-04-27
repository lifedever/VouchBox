import Foundation
import HelperProtocol
import VouchBoxCore

public actor HelperClient {
    private var connection: NSXPCConnection?

    public init() {}

    private func proxy() throws -> VouchBoxHelperProtocol {
        if connection == nil {
            let conn = NSXPCConnection(machServiceName: helperMachServiceName, options: .privileged)
            conn.remoteObjectInterface = NSXPCInterface(with: VouchBoxHelperProtocol.self)
            conn.invalidationHandler = { [weak self] in Task { await self?.invalidate() } }
            conn.interruptionHandler = { [weak self] in Task { await self?.invalidate() } }
            conn.resume()
            connection = conn
        }
        guard let p = connection?.remoteObjectProxyWithErrorHandler({ _ in }) as? VouchBoxHelperProtocol else {
            throw VouchBoxError.helperUnavailable(reason: "remote proxy cast failed")
        }
        return p
    }

    private func invalidate() {
        connection = nil
    }

    public func ping() async throws -> String {
        let p = try proxy()
        return await withCheckedContinuation { cont in
            p.ping { version in cont.resume(returning: version) }
        }
    }

    public func install(
        extractedBundlePath: String,
        bundleID: String,
        destPath: String,
        vbManagedKey: String = "VBManaged"
    ) async throws {
        let p = try proxy()
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            p.install(
                extractedBundlePath: extractedBundlePath,
                bundleID: bundleID,
                destPath: destPath,
                vbManagedKey: vbManagedKey
            ) { error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }
    }

    public func uninstall(path: String) async throws {
        let p = try proxy()
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            p.uninstall(path: path) { error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }
    }

    /// Fire-and-forget shutdown: helper will exit(0) after sending reply.
    /// We don't await the reply because helper may exit before reply is delivered,
    /// leaving the continuation hanging.
    public func shutdown() async {
        guard let p = try? proxy() else { return }
        p.shutdown { /* helper may have exited before this fires */ }
        try? await Task.sleep(nanoseconds: 250_000_000)
    }

    public func resignInPlace(path: String, bundleID: String) async throws {
        let p = try proxy()
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            p.resignInPlace(path: path, bundleID: bundleID) { error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }
    }
}
