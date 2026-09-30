#!/usr/bin/env bash
# Builds LastStats-macos.dmg: a disk image with the app + an "Applications"
# shortcut (drag-and-drop install). Run after "flutter build macos".
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP_SRC="$(ls -d "$ROOT"/build/macos/Build/Products/Release/*.app | head -1)"
STAGE="$ROOT/build/dmg-stage"

rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP_SRC" "$STAGE/LastStats.app"
ln -s /Applications "$STAGE/Applications"

rm -f "$ROOT/LastStats-macos.dmg"
hdiutil create -volname "LastStats" -srcfolder "$STAGE" -ov -format UDZO "$ROOT/LastStats-macos.dmg"
