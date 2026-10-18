#!/usr/bin/env bash
# Builds the Linux app, then .zip, .deb, .rpm, .AppImage (+ install script on x64).
# Usage: ci-build.sh <x64|arm64> <zip-name>
# Env: APP_VERSION (empty = dev build), RUN_NUMBER, REPO (owner/name)
set -euo pipefail

ARCH="$1"
ZIP="$2"
RUN="${RUN_NUMBER:-0}"
VERSION="${APP_VERSION:-0.0.0-dev.$RUN}"   # dev build: never claim to be a release

sudo apt-get update
sudo apt-get install -y \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++6 \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-libav \
  curl dpkg-dev rpm

flutter build linux --release --build-name="$VERSION" --build-number="$RUN"

(cd "build/linux/$ARCH/release/bundle" && zip -r "$GITHUB_WORKSPACE/$ZIP" .)

# Windows line endings would break the scripts on Linux
sed -i 's/\r$//' linux/packaging/*.sh
bash linux/packaging/build-deb.sh "$ARCH" "$VERSION"
bash linux/packaging/build-rpm.sh "$ARCH" "$VERSION"
bash linux/packaging/build-appimage.sh "$ARCH"

# One-line installer (same file for x64 and ARM64, so only the x64 job makes it)
if [ "$ARCH" = "x64" ]; then
  sed "s#__REPO__#${REPO:-}#g; s/\r$//" linux/packaging/install.sh > install-linux.sh
fi
