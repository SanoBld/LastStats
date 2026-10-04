#!/usr/bin/env bash
# Builds LastStats-linux-<arch>.deb (installer for Debian/Ubuntu/Mint...).
# Usage: build-deb.sh <x64|arm64> <version>   (run after "flutter build linux")
set -euo pipefail

ARCH="$1"; VERSION="$2"
case "$ARCH" in
  x64)   DEB_ARCH=amd64 ;;
  arm64) DEB_ARCH=arm64 ;;
  *) echo "Unknown arch: $ARCH"; exit 1 ;;
esac

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUNDLE="$ROOT/build/linux/$ARCH/release/bundle"
PKG="$ROOT/build/deb-$ARCH"
# Debian needs "~" (not "-") for pre-release suffixes: 2.7.0-beta -> 2.7.0~beta
DEB_VERSION="${VERSION//-/\~}"

rm -rf "$PKG"
mkdir -p "$PKG/DEBIAN" "$PKG/opt/laststats" "$PKG/usr/bin" \
         "$PKG/usr/share/applications" \
         "$PKG/usr/share/icons/hicolor/512x512/apps"

cp -r "$BUNDLE/." "$PKG/opt/laststats/"
ln -s /opt/laststats/LastStats "$PKG/usr/bin/laststats"
install -m 644 "$ROOT/linux/packaging/laststats.desktop" "$PKG/usr/share/applications/laststats.desktop"
install -m 644 "$ROOT/assets/images/icon-512.png" "$PKG/usr/share/icons/hicolor/512x512/apps/laststats.png"

cat > "$PKG/DEBIAN/control" <<CTRL
Package: laststats
Version: $DEB_VERSION
Section: sound
Priority: optional
Architecture: $DEB_ARCH
Maintainer: SanoBld <https://github.com/SanoBld>
Homepage: https://github.com/SanoBld/LastStats
Depends: libgtk-3-0, libglib2.0-0, libgstreamer1.0-0, libgstreamer-plugins-base1.0-0
Recommends: gstreamer1.0-plugins-good, gstreamer1.0-libav
Installed-Size: $(du -sk "$PKG/opt" | cut -f1)
Description: Last.fm statistics, charts and listening recaps
 LastStats shows your Last.fm listening history as charts, rankings,
 achievements and recap stories.
CTRL

# Refresh menu/icon caches after install and removal.
for s in postinst postrm; do
  cat > "$PKG/DEBIAN/$s" <<'SH'
#!/bin/sh
set -e
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database -q /usr/share/applications || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true
exit 0
SH
  chmod 755 "$PKG/DEBIAN/$s"
done

find "$PKG" -type d -exec chmod 755 {} +
dpkg-deb --build --root-owner-group "$PKG" "$ROOT/LastStats-linux-$ARCH.deb"
