import SwiftUI
import AppKit

struct MenuBarView: View {
    @Bindable var catalog: AppCatalog
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading) {
            Text("VouchBox").font(.headline).padding(.bottom, 4)
            let withUpdates = catalog.entries.compactMap { e -> (ManifestEntry, String)? in
                guard let m = e.manifest,
                      let installed = catalog.installedVersion(for: m.id),
                      installed != m.latest.version else { return nil }
                return (e, m.latest.version)
            }
            if withUpdates.isEmpty {
                Text("没有待更新").foregroundStyle(.secondary).font(.caption)
            } else {
                ForEach(withUpdates, id: \.0.id) { (entry, version) in
                    Text("\(entry.manifest?.name ?? "?") → \(version)").font(.caption)
                }
            }
            Divider()
            Button("打开主窗口") { openWindow(id: "main") }
            Button("立即检查更新") { Task { await catalog.refreshAll() } }
            Divider()
            Button("退出") { NSApplication.shared.terminate(nil) }
        }
        .padding(8)
        .frame(width: 240)
    }
}
