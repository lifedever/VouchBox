# VouchBox

**English** | [简体中文](README.zh.md)

> An open-source local distribution manager for macOS apps, giving indie apps without an Apple Developer ID the ability to **preserve system permissions across updates**.

Think of it as JetBrains Toolbox for indie macOS apps: install, update, uninstall — all in one place.
**What sets VouchBox apart**: it acts as a local *signing vouch* on the user's machine, so that apps without a Developer ID ($99/year) can keep their TCC permissions (Accessibility, Screen Recording, Microphone, etc.) after every update — no need to re-grant in System Settings → Privacy & Security each time.

## Status

🚧 Early development. P1–P3 implemented; P4 (Memo series onboarding) deferred. See [`docs/design.md`](docs/design.md) for the full architecture.

## What problem does this solve?

Indie developers who don't pay $99/year don't get a Developer ID certificate, so their macOS apps can only be ad-hoc signed. The fallout:

1. **Every update requires re-granting system permissions** (cdhash changes → TCC treats it as a brand new app)
2. **Gatekeeper blocks first launch** (quarantine attribute)
3. **Each app reinvents its own in-app updater**, and bugs are hard to fix in the field — once the updater itself ships broken, existing users can't be patched remotely

VouchBox solves all three on the client, once.

## Core idea (one line)

When VouchBox re-signs an app on install/update, it pins the **designated requirement** to the bundle ID rather than the cdhash. macOS's TCC then treats every future update of that app as the *same* app, and your previously granted permissions stick. See [`docs/design.md`](docs/design.md) §2 for the gory details.

## Who can plug into this?

The manifest protocol is open ([`docs/manifest-spec.md`](docs/manifest-spec.md)) — any macOS developer can write a manifest. **However, this project itself maintains only the lifedever built-in catalog**: no third-party PRs, no third-party app review, no endorsement.

Third parties have two paths:

1. **Host a manifest, let users add it manually**: write a JSON manifest per spec → host on an HTTPS URL → set the `VBManaged` flag in your app to disable self-update → users paste the URL into VouchBox. **The UI shows a "⚠ Third-party / use at your own risk" warning** for any manually added entry.
2. **Fork VouchBox and run your own**: replace the built-in catalog with your own apps, ship under your brand, take your own responsibility. The MIT license encourages this.

> **Disclaimer**: The lifedever-maintained version of VouchBox vouches *only* for apps in its built-in catalog. User-added third-party manifests, and any apps included in fork builds, are **not** the responsibility of this project. Installing a third-party app is equivalent to trusting that developer directly — VouchBox preserves the permissions you grant; it does **not** vet what those apps do with them.

## Features (V1 scope)

- 📋 **App catalog** — name, icon, tagline, screenshots, publisher, homepage, license, size, last-updated
- ⬇️ **Install** — download → SHA256 verify → strip quarantine → re-sign with stable DR → place in `/Applications`
- 🔄 **Update** — detect new version → show release notes diff → one-click upgrade (TCC preserved)
- 🗑️ **Uninstall** — remove from `/Applications`, optionally clear user data, with notes on how to manually clean TCC residue
- 🔔 **Update notifications** — periodic check + system notifications
- 🔒 **Signature verification** — Ed25519 publisher keys (publishers may sign manifests; unsigned manifests are loudly warned, never silently accepted)
- 🪞 **Self-management** — VouchBox updates itself through the same manifest protocol; on first launch it re-signs itself with a stable DR so its own future TCC grants are preserved

## Architecture & build

Pure Swift Package, no Xcode project. Targets:

```
VouchBox/
├── Package.swift
├── Sources/
│   ├── VouchBox/         # SwiftUI app (menu bar + main window)
│   ├── VouchBoxCLI/      # CLI: install / update / list / helper / sign-manifest
│   ├── VouchBoxHelper/   # Privileged helper (root) — XPC, writes /Applications
│   ├── VouchBoxCore/     # Shared types: Manifest, AppState, errors
│   ├── SignKit/          # codesign wrapper + DR helpers
│   ├── ManifestKit/      # fetch / parse / cache / Ed25519 verify
│   ├── InstallKit/       # download / SHA256 / unzip / coordinator
│   └── HelperProtocol/   # XPC interface
├── Tests/
└── scripts/
    ├── build-dev.sh      # builds .app, signs main + helper with stable DR
    └── ...
```

Build a development bundle:

```bash
./scripts/build-dev.sh
open .build/debug-bundle/VouchBox.app
```

The dev script signs both the main app and the privileged helper with stable designated requirements (`identifier "com.lifedever.vouchbox"` and `identifier "com.lifedever.vouchbox.helper"` respectively), bundles the helper into `Contents/MacOS/`, and registers the LaunchDaemon plist into `Contents/Library/LaunchDaemons/`.

## License

**MIT** — see `LICENSE`.

Forks are welcome — repackage as your own app management tool with your own catalog, your own brand, your own responsibility.

## Author

[lifedever](https://github.com/lifedever) (lifedever). Born out of real friction maintaining the Memo series of macOS apps.
