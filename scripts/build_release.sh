#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${VERSION:-0.1.0}"
DNGLAB_VERSION="${DNGLAB_VERSION:-v0.8.0}"
OUT="$ROOT/dist"
BASE="https://github.com/dnglab/dnglab/releases/download/${DNGLAB_VERSION}"

rm -rf "$OUT"
mkdir -p "$OUT"

write_launcher() {
  local dest="$1"
  cat > "$dest" << 'LAUNCH'
#!/usr/bin/env python3
"""Portable raw2dng — expects dnglab beside this file."""
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent


def find_dnglab() -> Path:
    env = os.environ.get("RAW2DNG_DNGLAB") or os.environ.get("DNGLAB")
    if env and Path(env).is_file():
        return Path(env)
    for name in ("dnglab", "dnglab.exe"):
        p = HERE / name
        if p.is_file():
            return p
    raise SystemExit("dnglab not found next to raw2dng. Re-download the release package.")


def usage() -> None:
    print(
        "Usage:\n"
        "  raw2dng <input.RAW> [output.dng]\n"
        "  raw2dng <input_dir> <output_dir>\n"
        "  raw2dng a.RAW b.RAW <output_dir>\n"
        "  raw2dng -r <input_dir> <output_dir>\n"
        "  raw2dng -f ...\n"
        "  raw2dng -V",
        file=sys.stderr,
    )


def main(argv: list[str]) -> int:
    if not argv or argv[0] in ("-h", "--help"):
        usage()
        return 0 if argv else 1
    if argv[0] in ("-V", "--version"):
        print("raw2dng 0.1.0 (portable)")
        return 0

    force = False
    recursive = False
    args: list[str] = []
    for a in argv:
        if a == "-f":
            force = True
        elif a == "-r":
            recursive = True
        elif a.startswith("-"):
            print(f"unknown option: {a}", file=sys.stderr)
            usage()
            return 1
        else:
            args.append(a)

    if not args:
        usage()
        return 1

    dnglab = find_dnglab()

    if len(args) == 1:
        inp = Path(args[0])
        if inp.is_dir():
            print("폴더 변환 시 출력 폴더 필요: raw2dng <in_dir> <out_dir>", file=sys.stderr)
            return 1
        out = inp.with_suffix(".dng")
        cmd = [str(dnglab), "convert"]
        if force:
            cmd.append("-f")
        cmd += [str(inp), str(out)]
        print(f"{inp.name} → {out}")
        return subprocess.call(cmd)

    out = Path(args[-1])
    inputs = [Path(x) for x in args[:-1]]

    if len(inputs) == 1 and inputs[0].is_dir():
        out.mkdir(parents=True, exist_ok=True)
        cmd = [str(dnglab), "convert"]
        if force:
            cmd.append("-f")
        if recursive:
            cmd.append("-r")
        cmd += [str(inputs[0]), str(out)]
        return subprocess.call(cmd)

    out.mkdir(parents=True, exist_ok=True)
    rc = 0
    for inp in inputs:
        dest = out / f"{inp.stem}.dng" if (out.is_dir() or len(inputs) > 1) else out
        if out.suffix.lower() == ".dng" and len(inputs) == 1:
            dest = out
        else:
            dest = out / f"{inp.stem}.dng"
            out.mkdir(parents=True, exist_ok=True)
        cmd = [str(dnglab), "convert"]
        if force:
            cmd.append("-f")
        cmd += [str(inp), str(dest)]
        print(f"{inp.name} → {dest}")
        r = subprocess.call(cmd)
        if r != 0:
            rc = r
    return rc


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
LAUNCH
  chmod +x "$dest"
}

write_win_cmd() {
  cat > "$1" << 'CMD'
@echo off
setlocal
set HERE=%~dp0
if "%~1"=="" (
  echo Usage: raw2dng.cmd input.RAW
  echo        raw2dng.cmd input.RAW output.dng
  echo        raw2dng.cmd input_dir output_dir
  exit /b 1
)
if /I "%~1"=="-V" (
  echo raw2dng 0.1.0 (portable)
  exit /b 0
)
if "%~2"=="" (
  "%HERE%dnglab.exe" convert -f "%~1" "%~dpn1.dng"
  exit /b %ERRORLEVEL%
)
"%HERE%dnglab.exe" convert -f %*
exit /b %ERRORLEVEL%
CMD
}

pack_dir() {
  local plat="$1"
  echo "$OUT/raw2dng-${VERSION}-${plat}"
}

# --- linux x64 ---
DIR="$(pack_dir linux-x64)"
mkdir -p "$DIR"
write_launcher "$DIR/raw2dng"
curl -fsSL -o "$DIR/dnglab" "$BASE/dnglab_linux_x64"
chmod +x "$DIR/dnglab"
cp "$ROOT/README.md" "$DIR/"
tar -C "$OUT" -czf "$OUT/raw2dng-${VERSION}-linux-x64.tar.gz" "raw2dng-${VERSION}-linux-x64"

# --- linux arm64 ---
DIR="$(pack_dir linux-arm64)"
mkdir -p "$DIR"
write_launcher "$DIR/raw2dng"
curl -fsSL -o "$DIR/dnglab" "$BASE/dnglab_linux_aarch64"
chmod +x "$DIR/dnglab"
cp "$ROOT/README.md" "$DIR/"
tar -C "$OUT" -czf "$OUT/raw2dng-${VERSION}-linux-arm64.tar.gz" "raw2dng-${VERSION}-linux-arm64"

# --- macos arm64 ---
DIR="$(pack_dir macos-arm64)"
mkdir -p "$DIR"
write_launcher "$DIR/raw2dng"
curl -fsSL -o "$DIR/_dng.zip" "$BASE/dnglab-macos-arm64_${DNGLAB_VERSION}.zip"
unzip -q -o "$DIR/_dng.zip" -d "$DIR/_z"
found="$(find "$DIR/_z" -type f -name 'dnglab*' | head -n1)"
cp "$found" "$DIR/dnglab"
chmod +x "$DIR/dnglab"
rm -rf "$DIR/_z" "$DIR/_dng.zip"
cp "$ROOT/README.md" "$DIR/"
tar -C "$OUT" -czf "$OUT/raw2dng-${VERSION}-macos-arm64.tar.gz" "raw2dng-${VERSION}-macos-arm64"

# --- windows x64 ---
DIR="$(pack_dir windows-x64)"
mkdir -p "$DIR"
write_win_cmd "$DIR/raw2dng.cmd"
write_launcher "$DIR/raw2dng.py"
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
src = out / "raw2dng-${VERSION}-windows-x64"
zpath = out / "raw2dng-${VERSION}-windows-x64.zip"
with zipfile.ZipFile(zpath, "w", zipfile.ZIP_DEFLATED) as z:
    for f in src.rglob("*"):
        if f.is_file():
            z.write(f, f.relative_to(out))
print("built", zpath)
PY

echo "Artifacts:"
ls -lh "$OUT"/*.{tar.gz,zip}
