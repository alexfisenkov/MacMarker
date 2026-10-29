#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_APP="$ROOT_DIR/dist/MacMarker.app"
TARGET_APP="/Applications/MacMarker.app"
STAGING_DIR=""
STAGED_APP=""
if [[ ! -d "$SOURCE_APP" ]]; then
  echo "Build the app first: $ROOT_DIR/script/build.sh" >&2
  exit 1
fi
if [[ ! -w /Applications ]]; then
  echo "This account cannot write to /Applications; install the app manually from $SOURCE_APP" >&2
  exit 1
fi

pkill -TERM -x MacMarker >/dev/null 2>&1 || true
for _ in {1..20}; do
  pgrep -x MacMarker >/dev/null || break
  sleep 0.1
done
if pgrep -x MacMarker >/dev/null; then
  echo "MacMarker did not exit within 2 seconds; leaving the installed app unchanged" >&2
  exit 1
fi

STAGING_DIR="$(mktemp -d /Applications/.MacMarker-install-XXXXXX)"
STAGED_APP="$STAGING_DIR/MacMarker.app"
cleanup() {
  if [[ -n "$STAGING_DIR" && -d "$STAGING_DIR" ]]; then
    rm -rf "$STAGING_DIR"
  fi
}
trap cleanup EXIT
ditto "$SOURCE_APP" "$STAGED_APP"
if ! codesign --verify --deep --strict "$STAGED_APP"; then
  echo "Staged app signature verification failed; installed app was left unchanged" >&2
  exit 1
fi

BACKUP_APP=""
if [[ -e "$TARGET_APP" ]]; then
  BACKUP_APP="/Applications/MacMarker.previous.$(date +%Y%m%d%H%M%S)-$$.app"
  mv "$TARGET_APP" "$BACKUP_APP"
fi
if ! mv "$STAGED_APP" "$TARGET_APP"; then
  if [[ -e "$TARGET_APP" ]]; then rm -rf "$TARGET_APP"; fi
  if [[ -n "$BACKUP_APP" && -e "$BACKUP_APP" ]]; then mv "$BACKUP_APP" "$TARGET_APP"; fi
  exit 1
fi
/usr/bin/open -n "$TARGET_APP"
echo "Installed $TARGET_APP"
