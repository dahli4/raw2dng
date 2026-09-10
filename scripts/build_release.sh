#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${VERSION:-0.2.0}"
DNGLAB_VERSION="${DNGLAB_VERSION:-v0.8.0}"
OUT="$ROOT/dist-release"
BASE="https://github.com/dnglab/dnglab/releases/download/${DNGLAB_VERSION}"
GUI_BIN="$ROOT/build/gui-bin/raw2dng-gui"

rm -rf "$OUT"
mkdir -p "$OUT"

# linux x64 — GUI binary + dnglab + optional cli
DIR="$OUT/raw2dng-${VERSION}-linux-x64"
mkdir -p "$DIR"
if [[ ! -f "$GUI_BIN" ]]; then
  echo "Missing $GUI_BIN — build with pyinstaller first" >&2
  exit 1
fi
cp "$GUI_BIN" "$DIR/raw2dng-gui"
chmod +x "$DIR/raw2dng-gui"
cp "$ROOT/scripts/portable_raw2dng.sh" "$DIR/raw2dng-cli"
chmod +x "$DIR/raw2dng-cli"
# bump cli version string inside copy
sed -i 's/0\.1\.1/0.2.0/g' "$DIR/raw2dng-cli" || true
curl -fsSL -o "$DIR/dnglab" "$BASE/dnglab_linux_x64"
chmod +x "$DIR/dnglab"
cp "$ROOT/README.md" "$DIR/"
printf '%s\n' "더블클릭 또는 ./raw2dng-gui 실행. dnglab은 같은 폴더에 둡니다." > "$DIR/사용법.txt"
tar -C "$OUT" -czf "$OUT/raw2dng-${VERSION}-linux-x64.tar.gz" "raw2dng-${VERSION}-linux-x64"

# linux arm64 — no GUI binary (built on x64); ship cli only + note
DIR="$OUT/raw2dng-${VERSION}-linux-arm64"
mkdir -p "$DIR"
cp "$ROOT/scripts/portable_raw2dng.sh" "$DIR/raw2dng-cli"
sed -i 's/0\.1\.1/0.2.0/g' "$DIR/raw2dng-cli" || true
chmod +x "$DIR/raw2dng-cli"
curl -fsSL -o "$DIR/dnglab" "$BASE/dnglab_linux_aarch64"
chmod +x "$DIR/dnglab"
cp "$ROOT/README.md" "$DIR/"
printf '%s\n' "이 패키지는 CLI(raw2dng-cli)입니다. GUI 바이너리는 linux-x64 패키지를 받으세요." > "$DIR/사용법.txt"
tar -C "$OUT" -czf "$OUT/raw2dng-${VERSION}-linux-arm64.tar.gz" "raw2dng-${VERSION}-linux-arm64"

# macos arm64 — osascript GUI + dnglab
DIR="$OUT/raw2dng-${VERSION}-macos-arm64"
mkdir -p "$DIR"
cp "$ROOT/scripts/portable_raw2dng_gui.mac.sh" "$DIR/raw2dng-gui.command"
chmod +x "$DIR/raw2dng-gui.command"
cp "$ROOT/scripts/portable_raw2dng.sh" "$DIR/raw2dng-cli"
sed -i 's/0\.1\.1/0.2.0/g' "$DIR/raw2dng-cli" || true
chmod +x "$DIR/raw2dng-cli"
curl -fsSL -o "$DIR/_dng.zip" "$BASE/dnglab-macos-arm64_${DNGLAB_VERSION}.zip"
unzip -q -o "$DIR/_dng.zip" -d "$DIR/_z"
found="$(find "$DIR/_z" -type f -name 'dnglab*' | head -n1)"
cp "$found" "$DIR/dnglab"
chmod +x "$DIR/dnglab"
rm -rf "$DIR/_z" "$DIR/_dng.zip"
cp "$ROOT/README.md" "$DIR/"
printf '%s\n' "raw2dng-gui.command 더블클릭 → 파일 선택 → DNG 생성" > "$DIR/사용법.txt"
tar -C "$OUT" -czf "$OUT/raw2dng-${VERSION}-macos-arm64.tar.gz" "raw2dng-${VERSION}-macos-arm64"

# windows — PowerShell WinForms GUI
DIR="$OUT/raw2dng-${VERSION}-windows-x64"
mkdir -p "$DIR"
cp "$ROOT/scripts/portable_raw2dng_gui.cmd" "$DIR/raw2dng-gui.cmd"
cp "$ROOT/scripts/portable_raw2dng_gui.ps1" "$DIR/raw2dng-gui.ps1"
cp "$ROOT/scripts/portable_raw2dng.cmd" "$DIR/raw2dng-cli.cmd"
sed -i 's/0\.1\.1/0.2.0/g' "$DIR/raw2dng-gui.ps1" "$DIR/raw2dng-cli.cmd" || true
curl -fsSL -o "$DIR/_dng.zip" "$BASE/dnglab-win-x64_${DNGLAB_VERSION}.zip"
unzip -q -o "$DIR/_dng.zip" -d "$DIR/_z"
found="$(find "$DIR/_z" -type f -iname 'dnglab*.exe' | head -n1)"
cp "$found" "$DIR/dnglab.exe"
rm -rf "$DIR/_z" "$DIR/_dng.zip"
cp "$ROOT/README.md" "$DIR/"
printf '%s\n' "raw2dng-gui.cmd 더블클릭. Python 설치 불필요." > "$DIR/사용법.txt"
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

ls -lh "$OUT"/*.{tar.gz,zip}
