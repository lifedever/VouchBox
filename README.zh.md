# VouchBox

[English](README.md) | **简体中文**

> 一个开源的 macOS App 本地分发管理器，为没有 Apple Developer ID 的独立 App 提供"更新后保留系统授权"的能力。

类似 JetBrains Toolbox：集中管理你装的工具、看更新、一键升级、一键卸载。
**与 Toolbox 的差异**：VouchBox 在用户机器上充当本地"签名担保人"（Vouch），让无 Developer ID（$99/年）的 App 也能在更新后保留 TCC 授权（辅助功能、屏幕录制、麦克风等），不用每次升级都重新到"系统设置 → 隐私"里点同意。

## 状态

🚧 设计阶段。详见 [`docs/design.md`](docs/design.md)。

## 解决什么问题

独立开发者不交 $99/年就拿不到 Developer ID 证书，发布的 macOS App 只能 ad-hoc 签名。后果：

1. **每次更新都要重新授权系统权限**（cdhash 变了 → TCC 当作新 App）
2. **Gatekeeper 拦截首次启动**（quarantine 标记）
3. **每个 App 自己造轮子做 in-app updater**，bug 难修复（一旦 updater 自身有 bug，存量用户无法远程救援）

VouchBox 把这三个问题在客户端一次性解决。

## 核心原理（一句话）

通过在重签时把代码签名的 designated requirement 锁死在 bundle ID 而非 cdhash 上，让 TCC 把新旧版本视为同一个 App，授权得以保留。详见 [`docs/design.md`](docs/design.md) §2。

## 谁可以接入

VouchBox 的 manifest 协议是公开的（[`docs/manifest-spec.md`](docs/manifest-spec.md)），任何 macOS App 开发者都能用。但本项目本身**只维护 lifedever 自家 App 的内置列表**，不收 PR、不审核第三方 App、不背书。

第三方有两条路：

1. **托管 manifest 让用户手动添加**：按 spec 编写 JSON manifest → 托管在 HTTPS URL → 在 App 内加 `VBManaged` flag 关掉自更新 → 用户在 VouchBox 输入 URL 添加。**用户在 UI 看到"⚠ 第三方来源 / 自担风险"警示**。
2. **fork VouchBox 自己运营**：把内置列表换成自己的 App，发自己品牌的客户端，独立担责。MIT 协议鼓励这么做。

> **免责声明**：VouchBox 项目（lifedever 维护版本）只对内置 lifedever 列表中的 App 负责。用户手动添加的第三方 manifest、fork 版本中收录的任何 App，与本项目无关。安装第三方 App 等同于"信任那个开发者本人"——VouchBox 只负责保留你给那个 App 的系统授权，不替开发者背书 App 的内容是否安全。

## 功能（V1 范围）

- 📋 **App 列表**：展示所有可装 App，含名称、图标、简介、截图、作者、官网、许可证、大小、最后更新时间
- ⬇️ **安装**：下载 → 校验 SHA256 → 剥离 quarantine → 重签为 stable DR → 入 `/Applications`
- 🔄 **更新**：检测新版本 → 差量提示 release notes → 一键升级（保留 TCC 授权）
- 🗑️ **卸载**：移除 `/Applications` 下的 .app + 可选清理用户数据 + 提示 TCC 残留如何手动清理
- 🔔 **更新提醒**：定时检查 + 系统通知
- 🔒 **签名验证**：Ed25519 publisher key 机制（manifest 由 publisher 私钥签名，VouchBox 验证；不强制 publisher 必须签，未签的会显著警示）
- 🪞 **自管自**：VouchBox 自身也通过同一套 manifest 协议自动更新（首次安装时自动重签自己以保未来 TCC 授权）

## 项目目录

```
VouchBox/
├── README.md
├── CLAUDE.md             # AI 会话上下文（项目背景 / 决策 / 待办）
├── docs/
│   ├── design.md         # 设计文档：核心机制、架构、风险、路线图
│   └── manifest-spec.md  # 第三方接入规范（manifest schema + App 端要求）
├── Package.swift         # Pure SPM (TBD)
├── Sources/
│   ├── VouchBox/         # App executable (SwiftUI)
│   ├── SignKit/          # 重签 + DR 管理
│   ├── ManifestKit/      # manifest 拉取 / 解析 / 缓存 / 校验
│   └── InstallKit/       # 下载、校验、安装、卸载
├── Tests/
└── scripts/
    ├── build-dev.sh
    └── build-release.sh
```

## 许可证

**MIT**。详见正式开 repo 后的 `LICENSE` 文件。

欢迎 fork 改造为你自己的 App 管理工具——把内置列表换成你的 App、用你的品牌、独立运营。

## 作者

[lifedever](https://github.com/lifedever) (lifedever)。本项目源于维护 Memo 系列 macOS App 时的实际痛点。
