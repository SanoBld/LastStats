#!/usr/bin/env bash
# Builds LastStats-macos.dmg: a disk image with the app + an "Applications"
# shortcut (drag-and-drop install). Run after "flutter build macos".
# Usage: build-dmg.sh [output-file-name]   (default: LastStats-macos.dmg)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP_SRC="$(ls -d "$ROOT"/build/macos/Build/Products/Release/*.app | head -1)"
STAGE="$ROOT/build/dmg-stage"
OUT_NAME="${1:-LastStats-macos.dmg}"

rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP_SRC" "$STAGE/LastStats.app"
ln -s /Applications "$STAGE/Applications"

rm -f "$ROOT/$OUT_NAME"
hdiutil create -volname "LastStats" -srcfolder "$STAGE" -ov -format UDZO "$ROOT/$OUT_NAME"
