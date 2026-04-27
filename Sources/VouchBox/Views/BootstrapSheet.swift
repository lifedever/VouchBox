import SwiftUI

struct BootstrapSheet: View {
    @Bindable var coordinator: BootstrapCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("一次性自我重签").font(.title2)
            Text("""
            VouchBox 自身的代码签名当前是临时格式。\
            需要执行一次自我重签，把签名锁定到 bundle ID，这样未来 VouchBox 升级时\
            你授予 VouchBox 的任何系统权限都能保留。

            操作过程：
            1. VouchBox 会通过 helper 重新签名自己（无需密码，只要 helper 已启用）。
            2. VouchBox 自动退出并重新打开。
            3. 整个过程约 5 秒。
            """).fixedSize(horizontal: false, vertical: true)

            switch coordinator.state {
            case .needsBootstrap:
                HStack {
                    Button("开始重签") { Task { await coordinator.executeBootstrap() } }
                        .buttonStyle(.borderedProminent)
                    Button("稍后再说") { dismiss() }
                }
            case .bootstrapping:
                ProgressView { Text("正在重签…") }
            case .error(let s):
                Text(s).foregroundStyle(.red).font(.caption).textSelection(.enabled)
                Button("重试") { Task { await coordinator.executeBootstrap() } }
            case .alreadyStable, .unknown:
                Text("无需重签。").foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: 480)
    }
}
