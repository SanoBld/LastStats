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

# --- Bundle the GStreamer libs and plugins (audio playback) so the AppImage is self-contained ---
LIBDIR="$APPDIR/usr/lib"
mkdir -p "$LIBDIR" "$APPDIR/usr/gst-plugins"
# System libs that every distro has: never bundle these
SKIP='linux-vdso|ld-linux|libc\.so|libm\.so|libdl|libpthread|librt|libutil|libresolv|libnss|libGL|libEGL|libX|libxcb|libdrm|libwayland|libvulkan|libgtk|libgdk|libgio|libglib|libgobject|libgmodule|libgthread|libpango|libcairo|libatk|libharfbuzz|libfontconfig|libfreetype|libepoxy|libstdc|libgcc_s'
copy_deps() {
  # Never fail here: "grep" finds nothing to copy once everything is bundled,
  # and with "set -e -o pipefail" that used to abort the whole build.
  { ldd "$1" 2>/dev/null | awk '/=> \//{print $3}' | grep -Ev "/($SKIP)[^/]*$" || true; } | while read -r l; do
    # portable "copy unless it already exists" (cp -n is deprecated and can
    # return an error on recent coreutils)
    [ -e "$LIBDIR/$(basename "$l")" ] || cp -L "$l" "$LIBDIR/" || true
  done
  return 0
}
# Libs used by the app itself
for f in "$APPDIR/usr/bin/LastStats" "$APPDIR/usr/bin/lib/"*.so; do if [ -e "$f" ]; then copy_deps "$f"; fi; done
# Only the plugins we need (keeps the file small)
TRIPLET="$(gcc -dumpmachine)"
GSTDIR="/usr/lib/$TRIPLET/gstreamer-1.0"
for p in coreelements typefind playback app audioconvert audioresample volume autodetect audioparsers \
         id3demux isomp4 matroska ogg vorbis opus flac wavparse wavpack mpg123 lame libav \
         pulseaudio alsa gio videoconvertscale videoconvert videoscale; do
  if [ -e "$GSTDIR/libgst$p.so" ]; then cp -L "$GSTDIR/libgst$p.so" "$APPDIR/usr/gst-plugins/"; fi
done
SCANNER="/usr/lib/$TRIPLET/gstreamer1.0/gstreamer-1.0/gst-plugin-scanner"
if [ -e "$SCANNER" ]; then cp -L "$SCANNER" "$APPDIR/usr/bin/gst-plugin-scanner"; fi
for f in "$APPDIR/usr/gst-plugins/"*.so "$APPDIR/usr/bin/gst-plugin-scanner"; do if [ -e "$f" ]; then copy_deps "$f"; fi; done
# Second pass (twice): libs needed by the libs we just copied
for _ in 1 2; do
  for f in "$LIBDIR/"*.so*; do if [ -e "$f" ]; then copy_deps "$f"; fi; done
done

# Check: the app and its audio plugin must find every library inside the
# AppImage (the AppImage catalog test failed with "libgstapp-1.0.so.0 not found").
MISSING="$(LD_LIBRARY_PATH="$LIBDIR:$APPDIR/usr/bin/lib" ldd "$APPDIR/usr/bin/LastStats" "$APPDIR/usr/bin/lib/"*.so 2>/dev/null | grep 'not found' | sort -u || true)"
if [ -n "$MISSING" ]; then
  echo "::warning::Libraries not found inside the AppImage:"; echo "$MISSING"
  if echo "$MISSING" | grep -q 'libgst'; then echo "::error::GStreamer library missing"; exit 1; fi
fi

sed 's/^Exec=.*/Exec=LastStats/' "$ROOT/linux/packaging/laststats.desktop" > "$APPDIR/laststats.desktop"
cp "$ROOT/assets/images/icon-512.png" "$APPDIR/laststats.png"
ln -sf laststats.png "$APPDIR/.DirIcon"

cat > "$APPDIR/AppRun" <<'SH'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
# Use the bundled libs and GStreamer plugins
export LD_LIBRARY_PATH="$HERE/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export GST_PLUGIN_PATH="$HERE/usr/gst-plugins"
export GST_PLUGIN_SYSTEM_PATH="$HERE/usr/gst-plugins"
export GST_PLUGIN_SCANNER="$HERE/usr/bin/gst-plugin-scanner"
export GST_REGISTRY_1_0="${XDG_CACHE_HOME:-$HOME/.cache}/laststats-gst-registry.bin"
exec "$HERE/usr/bin/LastStats" "$@"
SH
chmod +x "$APPDIR/AppRun"

curl -fsSL -o "$ROOT/build/appimagetool" \
  "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$MACHINE.AppImage"
chmod +x "$ROOT/build/appimagetool"

# APPIMAGE_EXTRACT_AND_RUN: CI runners have no FUSE.
ARCH="$MACHINE" APPIMAGE_EXTRACT_AND_RUN=1 \
  "$ROOT/build/appimagetool" "$APPDIR" "$ROOT/LastStats-$MACHINE.AppImage"
