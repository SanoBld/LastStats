#!/usr/bin/env bash
# LastStats installer for Linux: picks the right package for your distro + CPU.
#   curl -fsSL https://github.com/__REPO__/releases/latest/download/install-linux.sh | bash
# Uses the latest stable release. Needs: curl.
set -euo pipefail

REPO="__REPO__"
case "$(uname -m)" in
  x86_64|amd64)  A=x64 ;;
  aarch64|arm64) A=arm64 ;;
  *) echo "Unsupported CPU: $(uname -m)"; exit 1 ;;
esac

BASE="https://github.com/$REPO/releases/latest/download"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
dl() { echo "Downloading $1 ..."; curl -fL --progress-bar -o "$TMP/$1" "$BASE/$1"; }

if command -v apt-get >/dev/null 2>&1; then
  F="LastStats-linux-$A.deb"; dl "$F"
  chmod 644 "$TMP/$F"
  $SUDO apt-get install -y "$TMP/$F"
elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
  F="LastStats-linux-$A.rpm"; dl "$F"
  PM="dnf"; command -v dnf >/dev/null 2>&1 || PM="yum"
  $SUDO "$PM" install -y "$TMP/$F"
elif command -v zypper >/dev/null 2>&1; then
  F="LastStats-linux-$A.rpm"; dl "$F"
  $SUDO zypper --non-interactive --no-gpg-checks install "$TMP/$F"
else
  # Any other distro: portable AppImage in your home folder (no root needed).
  F="LastStats-linux-$A.AppImage"; dl "$F"
  mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.local/share/icons"
  install -m 755 "$TMP/$F" "$HOME/.local/bin/laststats"
  ( cd "$TMP" && "$HOME/.local/bin/laststats" --appimage-extract laststats.png >/dev/null 2>&1 \
      && cp squashfs-root/laststats.png "$HOME/.local/share/icons/laststats.png" ) || true
  cat > "$HOME/.local/share/applications/laststats.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=LastStats
Exec=$HOME/.local/bin/laststats
Icon=$HOME/.local/share/icons/laststats.png
Terminal=false
Categories=AudioVideo;Audio;Music;
DESK
fi
echo "LastStats installed. Launch it from your app menu or run: laststats"
