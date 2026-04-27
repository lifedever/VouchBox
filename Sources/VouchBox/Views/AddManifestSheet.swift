import SwiftUI

struct AddManifestSheet: View {
    @Bindable var catalog: AppCatalog
    @Environment(\.dismiss) private var dismiss

    @State private var input = ""
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("添加 Manifest URL").font(.title2)
            Text("注意：第三方来源的 App 不在 lifedever 维护范围内，安装风险由你自负。建议确认 publisher 身份与 manifest 是否带签名。")
                .font(.caption).foregroundStyle(.secondary)
            TextField("https://...", text: $input)
                .textFieldStyle(.roundedBorder)
            if let e = error {
                Text(e).foregroundStyle(.red).font(.caption)
            }
            HStack {
                Spacer()
                Button("取消") { dismiss() }
                Button("添加") { add() }.buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 480)
    }

    private func add() {
        guard let url = URL(string: input.trimmingCharacters(in: .whitespaces)),
              url.scheme == "https" else {
            error = "需要合法的 HTTPS URL"
            return
        }
        catalog.addUserManifest(url)
        Task { await catalog.refreshAll() }
        dismiss()
    }
}
