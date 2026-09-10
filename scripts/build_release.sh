#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${VERSION:-0.1.1}"
DNGLAB_VERSION="${DNGLAB_VERSION:-v0.8.0}"
OUT="$ROOT/dist"
BASE="https://github.com/dnglab/dnglab/releases/download/${DNGLAB_VERSION}"

rm -rf "$OUT"
mkdir -p "$OUT"

pack_dir() {
  echo "$OUT/raw2dng-${VERSION}-$1"
}

DIR="$(pack_dir linux-x64)"
mkdir -p "$DIR"
cp "$ROOT/scripts/portable_raw2dng.sh" "$DIR/raw2dng"
chmod +x "$DIR/raw2dng"
curl -fsSL -o "$DIR/dnglab" "$BASE/dnglab_linux_x64"
chmod +x "$DIR/dnglab"
cp "$ROOT/README.md" "$DIR/"
tar -C "$OUT" -czf "$OUT/raw2dng-${VERSION}-linux-x64.tar.gz" "raw2dng-${VERSION}-linux-x64"

DIR="$(pack_dir linux-arm64)"
mkdir -p "$DIR"
cp "$ROOT/scripts/portable_raw2dng.sh" "$DIR/raw2dng"
chmod +x "$DIR/raw2dng"
curl -fsSL -o "$DIR/dnglab" "$BASE/dnglab_linux_aarch64"
chmod +x "$DIR/dnglab"
cp "$ROOT/README.md" "$DIR/"
tar -C "$OUT" -czf "$OUT/raw2dng-${VERSION}-linux-arm64.tar.gz" "raw2dng-${VERSION}-linux-arm64"

DIR="$(pack_dir macos-arm64)"
mkdir -p "$DIR"
cp "$ROOT/scripts/portable_raw2dng.sh" "$DIR/raw2dng"
chmod +x "$DIR/raw2dng"
curl -fsSL -o "$DIR/_dng.zip" "$BASE/dnglab-macos-arm64_${DNGLAB_VERSION}.zip"
unzip -q -o "$DIR/_dng.zip" -d "$DIR/_z"
found="$(find "$DIR/_z" -type f -name 'dnglab*' | head -n1)"
cp "$found" "$DIR/dnglab"
chmod +x "$DIR/dnglab"
rm -rf "$DIR/_z" "$DIR/_dng.zip"
cp "$ROOT/README.md" "$DIR/"
tar -C "$OUT" -czf "$OUT/raw2dng-${VERSION}-macos-arm64.tar.gz" "raw2dng-${VERSION}-macos-arm64"

DIR="$(pack_dir windows-x64)"
mkdir -p "$DIR"
cp "$ROOT/scripts/portable_raw2dng.cmd" "$DIR/raw2dng.cmd"
curl -fsSL -o "$DIR/_dng.zip" "$BASE/dnglab-win-x64_${DNGLAB_VERSION}.zip"
unzip -q -o "$DIR/_dng.zip" -d "$DIR/_z"
found="$(find "$DIR/_z" -type f -iname 'dnglab*.exe' | head -n1)"
cp "$found" "$DIR/dnglab.exe"
rm -rf "$DIR/_z" "$DIR/_dng.zip"
cp "$ROOT/README.md" "$DIR/"
python3 - << PY
import zipfile
from pathlib import Path
out = Path("$OUT")
ver = "$VERSION"
src = out / f"raw2dng-{ver}-windows-x64"
zpath = out / f"raw2dng-{ver}-windows-x64.zip"
with zipfile.ZipFile(zpath, "w", zipfile.ZIP_DEFLATED) as z:
    for f in src.rglob("*"):
        if f.is_file():
            z.write(f, f.relative_to(out))
print("built", zpath)
PY

echo "Artifacts:"
ls -lh "$OUT"/*.{tar.gz,zip}
