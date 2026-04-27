import SwiftUI

struct AppListView: View {
    @Bindable var catalog: AppCatalog
    @Binding var selection: ManifestEntry.ID?

    var body: some View {
        List(selection: $selection) {
            Section("Lifedever Apps") {
                ForEach(catalog.entries.filter { $0.source == .builtIn }) { entry in
                    row(entry).tag(Optional(entry.id))
                }
            }
            if catalog.entries.contains(where: { $0.source == .userAdded }) {
                Section("Manually Added (Third-Party)") {
                    ForEach(catalog.entries.filter { $0.source == .userAdded }) { entry in
                        row(entry).tag(Optional(entry.id))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .overlay {
            if catalog.refreshing {
                ProgressView().controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private func row(_ entry: ManifestEntry) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 6)
                .fill(.tertiary)
                .frame(width: 32, height: 32)
                .overlay(Text(initials(entry)).font(.caption))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.manifest?.name ?? entry.manifestURL.host ?? "?")
                    .lineLimit(1)
                if let m = entry.manifest {
                    Text(m.tagline).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                } else if let err = entry.fetchError {
                    Text(err).font(.caption).foregroundStyle(.red).lineLimit(1)
                } else {
                    Text("loading…").font(.caption).foregroundStyle(.secondary)
                }
                badges(for: entry)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func badges(for entry: ManifestEntry) -> some View {
        HStack(spacing: 4) {
            if entry.source == .userAdded {
                WarningBadge(style: .thirdParty, text: "第三方")
            }
            if entry.verification == .unsigned {
                WarningBadge(style: .unsigned, text: "未签名")
            }
            if entry.verification == .invalid {
                WarningBadge(style: .error, text: "签名无效")
            }
            if let m = entry.manifest, let installed = catalog.installedVersion(for: m.id) {
                Text(installed == m.latest.version ? "已最新" : "可更新")
                    .font(.caption2)
                    .foregroundStyle(installed == m.latest.version ? Color.secondary : Color.blue)
            }
        }
    }

    private func initials(_ entry: ManifestEntry) -> String {
        if let n = entry.manifest?.name, let first = n.first {
            return String(first)
        }
        return "?"
    }
}
