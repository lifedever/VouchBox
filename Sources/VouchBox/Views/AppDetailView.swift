import SwiftUI
import VouchBoxCore
import InstallKit

struct AppDetailView: View {
    @Bindable var catalog: AppCatalog
    let entry: ManifestEntry

    @State private var installing = false
    @State private var progressLine = ""
    @State private var lastError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                badgeRow
                if let m = entry.manifest {
                    Divider()
                    actionRow(m)
                    if !m.description.isEmpty {
                        Text("简介").font(.headline)
                        Text(m.description).textSelection(.enabled)
                    }
                    if let perms = m.permissions, !perms.isEmpty {
                        permissionsSection(perms)
                    }
                    if let notes = m.latest.releaseNotes {
                        Text("更新内容（\(m.latest.version)）").font(.headline)
                        Text(notes).textSelection(.enabled)
                    }
                    metaSection(m)
                }
                if let err = lastError {
                    Text(err).foregroundStyle(.red).textSelection(.enabled)
                }
                if installing {
                    ProgressView { Text(progressLine) }
                }
                Spacer()
            }
            .padding()
        }
    }

    @ViewBuilder
    private var header: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12).fill(.tertiary).frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.manifest?.name ?? entry.manifestURL.host ?? "?").font(.title)
                if let t = entry.manifest?.tagline {
                    Text(t).foregroundStyle(.secondary)
                }
                if let pub = entry.manifest?.publisher {
                    Link(pub.name, destination: pub.url).font(.caption)
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var badgeRow: some View {
        HStack {
            if entry.source == .userAdded {
                WarningBadge(style: .thirdParty, text: "第三方来源 / 自担风险")
            }
            switch entry.verification {
            case .verified(let fp):
                Label("已签名 (key: \(fp))", systemImage: "checkmark.seal.fill")
                    .font(.caption).foregroundStyle(Color.green)
            case .unsigned:
                WarningBadge(style: .unsigned, text: "未签名 manifest")
            case .invalid:
                WarningBadge(style: .error, text: "签名验证失败")
            case .none:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func actionRow(_ m: Manifest) -> some View {
        HStack {
            let installed = catalog.installedVersion(for: m.id)
            if let installed {
                if installed == m.latest.version {
                    Button("已最新（重装）") { perform(.install, m) }
                } else {
                    Button("更新到 \(m.latest.version)") { perform(.install, m) }
                        .buttonStyle(.borderedProminent)
                }
                Button("卸载", role: .destructive) { perform(.uninstall, m) }
            } else {
                Button("安装 \(m.latest.version)") { perform(.install, m) }
                    .buttonStyle(.borderedProminent)
            }
            Spacer()
            if let v = installed {
                Text("已装版本：\(v)").foregroundStyle(.secondary)
            }
        }
        .disabled(installing)
    }

    @ViewBuilder
    private func permissionsSection(_ perms: [Permission]) -> some View {
        Text("权限").font(.headline)
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(perms.enumerated()), id: \.offset) { _, p in
                HStack(alignment: .top) {
                    Image(systemName: "lock.shield")
                    VStack(alignment: .leading) {
                        Text(p.type).font(.subheadline.weight(.medium))
                        Text(p.reason).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func metaSection(_ m: Manifest) -> some View {
        Divider()
        VStack(alignment: .leading, spacing: 4) {
            metaRow("Bundle ID", m.id)
            metaRow("许可证", m.license ?? "—")
            metaRow("发布日期", m.latest.publishedAt.formatted(date: .abbreviated, time: .omitted))
            if let src = m.sourceURL {
                Link(src.absoluteString, destination: src)
            }
        }.font(.caption)
    }

    private func metaRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).foregroundStyle(.secondary); Text(value) }
    }

    private enum Action { case install, uninstall }

    private func perform(_ action: Action, _ m: Manifest) {
        Task {
            installing = true
            lastError = nil
            defer { installing = false; progressLine = "" }
            do {
                switch action {
                case .install:
                    try await catalog.install(entry) { p in
                        Task { @MainActor in progressLine = "[\(p.phase.rawValue)] \(p.detail)" }
                    }
                case .uninstall:
                    try await catalog.uninstall(bundleID: m.id)
                }
            } catch {
                lastError = String(describing: error)
            }
        }
    }
}
