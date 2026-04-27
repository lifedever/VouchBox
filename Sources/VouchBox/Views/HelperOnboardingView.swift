import SwiftUI
import InstallKit

struct HelperOnboardingView: View {
    @Bindable var helper: HelperStatusModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("启用 VouchBox Helper").font(.title2)
            Text("""
            VouchBox 需要一个特权 helper 才能写入 /Applications 目录。\
            点击「启用」会请求一次系统密码，之后所有安装/更新/卸载操作都无需再输密码。
            """).fixedSize(horizontal: false, vertical: true)

            switch helper.status {
            case .notRegistered:
                Button("启用 Helper") { Task { await helper.register() } }
                    .buttonStyle(.borderedProminent)
            case .requiresApproval:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Helper 已注册，等待系统设置中授权。").foregroundStyle(.orange)
                    Button("打开系统设置") { Task { await helper.openApprovalSettings() } }
                }
            case .enabled:
                HStack {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                    Text("Helper 已启用")
                    if let v = helper.helperVersion {
                        Text("(v\(v))").foregroundStyle(.secondary)
                    }
                }
            case .unknown(let raw):
                VStack(alignment: .leading, spacing: 8) {
                    Text("Helper 状态：notFound (\(raw))").foregroundStyle(.red)
                    Text("通常是因为 VouchBox.app 不在 /Applications/ 目录下。请先把 VouchBox.app 拖入 /Applications/，再重新打开。")
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("仍然尝试启用") { Task { await helper.register() } }
                }
            }

            if let err = helper.lastError {
                Text(err).font(.caption).foregroundStyle(.red).textSelection(.enabled)
            }
        }
        .padding()
        .frame(width: 480)
        .task { await helper.refresh() }
    }
}
