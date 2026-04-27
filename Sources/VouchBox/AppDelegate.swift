import AppKit
import InstallKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        Task.detached(priority: .userInitiated) {
            await HelperClient().shutdown()
            await MainActor.run {
                NSApp.reply(toApplicationShouldTerminate: true)
            }
        }
        return .terminateLater
    }

    /// Quit fully when last window closes too — VouchBox is a menu-bar app, but
    /// also leaves the helper running otherwise.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
