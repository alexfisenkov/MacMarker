#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/MacMarker.app"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
if [[ -z "$NOTARY_PROFILE" ]]; then
  echo "Set NOTARY_PROFILE to an existing notarytool Keychain profile name" >&2
  exit 2
fi
if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "Build the app first: $ROOT_DIR/script/build.sh" >&2
  exit 1
fi

ARCHIVE_DIR="$ROOT_DIR/dist/notarization"
SUBMISSION_ZIP="$ARCHIVE_DIR/MacMarker-notarization.zip"
FINAL_ZIP="$ROOT_DIR/dist/MacMarker-notarized.zip"
mkdir -p "$ARCHIVE_DIR"
rm -f "$SUBMISSION_ZIP" "$FINAL_ZIP"
ditto -c -k --keepParent "$APP_BUNDLE" "$SUBMISSION_ZIP"
xcrun notarytool submit "$SUBMISSION_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP_BUNDLE"
xcrun stapler validate "$APP_BUNDLE"
ditto -c -k --keepParent "$APP_BUNDLE" "$FINAL_ZIP"
echo "Notarized app archive: $FINAL_ZIP"
