import Foundation
import HelperProtocol

final class HelperListener: NSObject, NSXPCListenerDelegate {
    private let listener: NSXPCListener
    private let impl = HelperImpl()

    init(machServiceName: String) {
        self.listener = NSXPCListener(machServiceName: machServiceName)
        super.init()
        listener.delegate = self
    }

    func resume() {
        listener.resume()
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection conn: NSXPCConnection) -> Bool {
        // V0.1: accept all connections to this mach service.
        // V0.2 hardening: validate auditToken / DR of caller against VouchBox main app stable DR.
        conn.exportedInterface = NSXPCInterface(with: VouchBoxHelperProtocol.self)
        conn.exportedObject = impl
        conn.resume()
        return true
    }
}
