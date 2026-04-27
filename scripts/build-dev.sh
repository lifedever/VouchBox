#!/usr/bin/env bash
# Dev build: produces a development VouchBox.app with helper bundled and both signed with stable DR.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIG="${CONFIG:-debug}"
APP_NAME="VouchBox.app"
BUILD_DIR="$ROOT/.build/$CONFIG-bundle"
APP_BUNDLE="$BUILD_DIR/$APP_NAME"
MAIN_BUNDLE_ID="com.lifedever.vouchbox"
HELPER_BUNDLE_ID="com.lifedever.vouchbox.helper"

echo "==> Building Swift targets ($CONFIG)"
swift build -c "$CONFIG" --product vouchbox
swift build -c "$CONFIG" --product "$HELPER_BUNDLE_ID"

BIN_PATH="$(swift build -c "$CONFIG" --show-bin-path)"

echo "==> Assembling .app bundle at $APP_BUNDLE"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Library/LaunchDaemons"

cp "$BIN_PATH/vouchbox" "$APP_BUNDLE/Contents/MacOS/VouchBox"
cp "$BIN_PATH/$HELPER_BUNDLE_ID" "$APP_BUNDLE/Contents/MacOS/$HELPER_BUNDLE_ID"
cp "$ROOT/Resources/com.lifedever.vouchbox.helper.plist" "$APP_BUNDLE/Contents/Library/LaunchDaemons/"

# Glob copy SPM resource bundles — never hardcode bundle names (CLAUDE.md global rule §1).
for bundle in "$BIN_PATH"/*.bundle; do
    [ -d "$bundle" ] && cp -R "$bundle" "$APP_BUNDLE/Contents/" || true
done

cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>$MAIN_BUNDLE_ID</string>
    <key>CFBundleExecutable</key>
    <string>VouchBox</string>
    <key>CFBundleName</key>
    <string>VouchBox</string>
    <key>CFBundleVersion</key>
    <string>0.1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>SMPrivilegedExecutables</key>
    <dict>
        <key>$HELPER_BUNDLE_ID</key>
        <string>identifier "$HELPER_BUNDLE_ID"</string>
    </dict>
</dict>
</plist>
EOF

echo "==> Signing helper with stable DR"
codesign --force --deep --no-strict --sign - \
    --identifier "$HELPER_BUNDLE_ID" \
    --requirements "=designated => identifier \"$HELPER_BUNDLE_ID\"" \
    "$APP_BUNDLE/Contents/MacOS/$HELPER_BUNDLE_ID"

echo "==> Signing main app with stable DR (no --deep, preserve helper signature)"
codesign --force --no-strict --sign - \
    --identifier "$MAIN_BUNDLE_ID" \
    --requirements "=designated => identifier \"$MAIN_BUNDLE_ID\"" \
    "$APP_BUNDLE"

echo "==> Removing quarantine"
xattr -dr com.apple.quarantine "$APP_BUNDLE" || true

echo "==> Done: $APP_BUNDLE"
echo
echo "Next steps:"
echo "  1. Open: open $APP_BUNDLE  (or run cli: $APP_BUNDLE/Contents/MacOS/VouchBox helper install)"
echo "  2. Approve helper in System Settings → Login Items & Extensions"
echo "  3. Test install: $APP_BUNDLE/Contents/MacOS/VouchBox install <manifest URL>"
