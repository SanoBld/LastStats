#!/usr/bin/env bash
# Builds LastStats-linux-<arch>.AppImage (single portable file, any distro).
# Usage: build-appimage.sh <x64|arm64>   (run after "flutter build linux")
set -euo pipefail

ARCH="$1"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUNDLE="$ROOT/build/linux/$ARCH/release/bundle"
APPDIR="$ROOT/build/AppDir-$ARCH"
MACHINE="$(uname -m)"   # x86_64 or aarch64 (this script runs on a native runner)

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
cp -r "$BUNDLE/." "$APPDIR/usr/bin/"

sed 's/^Exec=.*/Exec=LastStats/' "$ROOT/linux/packaging/laststats.desktop" > "$APPDIR/laststats.desktop"
cp "$ROOT/assets/images/icon-512.png" "$APPDIR/laststats.png"
ln -sf laststats.png "$APPDIR/.DirIcon"

cat > "$APPDIR/AppRun" <<'SH'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/LastStats" "$@"
SH
chmod +x "$APPDIR/AppRun"

curl -fsSL -o "$ROOT/build/appimagetool" \
  "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$MACHINE.AppImage"
chmod +x "$ROOT/build/appimagetool"

# APPIMAGE_EXTRACT_AND_RUN: CI runners have no FUSE.
ARCH="$MACHINE" APPIMAGE_EXTRACT_AND_RUN=1 \
  "$ROOT/build/appimagetool" "$APPDIR" "$ROOT/LastStats-linux-$ARCH.AppImage"
