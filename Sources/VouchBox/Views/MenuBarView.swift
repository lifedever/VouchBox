import SwiftUI
import AppKit
import VouchBoxCore

struct MenuBarView: View {
    @Bindable var catalog: AppCatalog
    @Environment(\.openWindow) private var openWindow

    private var allWithManifest: [(ManifestEntry, Manifest)] {
        catalog.entries.compactMap { e in
            guard let m = e.manifest else { return nil }
            return (e, m)
        }
    }

    private var updates: [(ManifestEntry, Manifest, String)] {
        allWithManifest.compactMap { (e, m) in
            guard let installed = catalog.installedVersion(for: m.id),
                  installed != m.latest.version else { return nil }
            return (e, m, m.latest.version)
        }
    }

    private var totalCount: Int { allWithManifest.count }
    private var upToDateCount: Int { totalCount - updates.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if updates.isEmpty {
                emptyState
            } else {
                listSection
            }
            Divider()
            actionSection
        }
        .frame(width: 300)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 16))
                .foregroundStyle(.tint)
            Text("VouchBox").font(.headline)
            Spacer()
            Text("\(upToDateCount)/\(totalCount)")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        Text("全部已是最新")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
    }

    private var listSection: some View {
        VStack(spacing: 0) {
            sectionLabel("可更新")
            ForEach(updates, id: \.0.id) { (entry, manifest, version) in
                UpdateRow(name: manifest.name, version: version)
            }
        }
        .padding(.vertical, 4)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.top, 6)
            .padding(.bottom, 2)
    }

    private var actionSection: some View {
        VStack(spacing: 0) {
            ActionRow(title: "打开主窗口") { openWindow(id: "main") }
            ActionRow(title: "立即检查更新") { Task { await catalog.refreshAll() } }
            ActionRow(title: "退出 VouchBox") { NSApplication.shared.terminate(nil) }
        }
        .padding(.vertical, 4)
    }
}

private struct UpdateRow: View {
    let name: String
    let version: String
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            Text(name)
                .font(.system(.body))
                .lineLimit(1)
            Spacer()
            Text("→ \(version)")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(hovering ? Color.primary.opacity(0.06) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }
}

private struct ActionRow: View {
    let title: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(.body))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(hovering ? Color.primary.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
