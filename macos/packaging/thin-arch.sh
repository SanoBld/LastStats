#!/usr/bin/env bash
# Usage: thin-arch.sh <folder containing the .app> <x64|arm64>
# "flutter build macos --release" always produces a universal app (Intel +
# Apple Silicon). This strips the other architecture from every universal
# Mach-O file inside the app, then re-signs it ad-hoc (editing the binaries
# invalidates the existing signature).
set -euo pipefail

DIR="$1"
case "$2" in
  x64)   LIPO_ARCH="x86_64" ;;
  arm64) LIPO_ARCH="arm64" ;;
  *) echo "Unknown arch: $2 (expected x64 or arm64)" >&2; exit 1 ;;
esac

APP="$(ls -d "$DIR"/*.app | head -1)"

while IFS= read -r -d '' f; do
  if file "$f" | grep -q "Mach-O universal binary"; then
    lipo "$f" -thin "$LIPO_ARCH" -output "$f.thin"
    # cat (not mv) keeps the original file permissions, e.g. the exec bit.
    cat "$f.thin" > "$f"
    rm "$f.thin"
  fi
done < <(find "$APP" -type f -print0)

codesign --force --deep --sign - "$APP"
echo "Thinned $APP to $LIPO_ARCH"
