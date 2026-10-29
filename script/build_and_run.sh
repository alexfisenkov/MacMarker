#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="MacMarker"
APP_BUNDLE="$ROOT_DIR/dist/MacMarker.app"
MODE="${1:-run}"
BUILD_ARGS=()
if [[ "$MODE" == "--debug" || "$MODE" == "debug" ]]; then
  BUILD_ARGS+=(--debug)
  MODE="run"
elif [[ $# -gt 1 ]]; then
  echo "usage: $0 [--debug|--logs|--telemetry|--verify]" >&2
  exit 2
fi
case "$MODE" in
  run|--logs|logs|--telemetry|telemetry|--verify|verify) ;;
  *) echo "usage: $0 [--debug|--logs|--telemetry|--verify]" >&2; exit 2 ;;
esac

# The app keeps no user data beyond preferences; stop it cleanly before replacing its bundle.
pkill -TERM -x "$APP_NAME" >/dev/null 2>&1 || true
"$ROOT_DIR/script/build.sh" "${BUILD_ARGS[@]}"

case "$MODE" in
  run)
    /usr/bin/open -n "$APP_BUNDLE"
    ;;
  --verify|verify)
    /usr/bin/open -n "$APP_BUNDLE"
    for _ in {1..20}; do
      pgrep -x "$APP_NAME" >/dev/null && exit 0
      sleep 0.25
    done
    echo "MacMarker process did not start" >&2
    exit 1
    ;;
  --logs|logs)
    /usr/bin/open -n "$APP_BUNDLE"
    /usr/bin/log stream --info --style compact --predicate 'process == "MacMarker"'
    ;;
  --telemetry|telemetry)
    /usr/bin/open -n "$APP_BUNDLE"
    /usr/bin/log stream --info --style compact --predicate 'subsystem == "com.alexfisenkov.macmarker"'
    ;;
esac
