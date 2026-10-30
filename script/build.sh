#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${BUILD_CONFIGURATION:-release}"

if [[ "${1:-}" == "--debug" ]]; then
  CONFIGURATION="debug"
elif [[ $# -gt 0 ]]; then
  echo "usage: $0 [--debug]" >&2
  exit 2
fi
if [[ "$CONFIGURATION" != "debug" && "$CONFIGURATION" != "release" ]]; then
  echo "BUILD_CONFIGURATION must be debug or release" >&2
  exit 2
fi

cd "$ROOT_DIR"
swift build -c "$CONFIGURATION"
BUILD_BINARY="$ROOT_DIR/.build/$CONFIGURATION/MacMarker"
if [[ ! -x "$BUILD_BINARY" ]]; then
  echo "SwiftPM product not found: $BUILD_BINARY" >&2
  exit 1
fi

SOURCE_REVISION="$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || printf 'working-tree')"
APP_BUNDLE="$ROOT_DIR/dist/MacMarker.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
ICONSET_DIR="$ROOT_DIR/dist/.MacMarker.iconset"
ICON_FILE="$APP_RESOURCES/AppIcon.icns"
rm -rf "$APP_BUNDLE"
rm -rf "$ICONSET_DIR"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_MACOS/MacMarker"
chmod 755 "$APP_MACOS/MacMarker"
swift "$ROOT_DIR/script/generate_icon.swift" "$ICONSET_DIR"
iconutil -c icns "$ICONSET_DIR" -o "$ICON_FILE"
rm -rf "$ICONSET_DIR"

if [[ -d "$ROOT_DIR/Resources" ]]; then
  while IFS= read -r -d '' RESOURCE; do
    cp -R "$RESOURCE" "$APP_RESOURCES/"
  done < <(find "$ROOT_DIR/Resources" -mindepth 1 -maxdepth 1 -print0)
fi

cat >"$APP_CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>MacMarker</string>
  <key>CFBundleIdentifier</key><string>com.alexfisenkov.macmarker</string>
  <key>CFBundleName</key><string>MacMarker</string>
  <key>CFBundleDisplayName</key><string>MacMarker</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleShortVersionString</key><string>0.1.1</string>
  <key>CFBundleVersion</key><string>2</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSHumanReadableCopyright</key><string>Copyright © 2026 Alexander Fisenkov</string>
  <key>MacMarkerSourceRevision</key><string>$SOURCE_REVISION</string>
</dict>
</plist>
PLIST

if [[ -n "${SIGNING_IDENTITY:-}" ]]; then
  codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$APP_BUNDLE"
else
  codesign --force --sign - "$APP_BUNDLE"
fi
echo "Built $APP_BUNDLE ($CONFIGURATION, source $SOURCE_REVISION)"
