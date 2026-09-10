#!/usr/bin/env bash
set -euo pipefail

VERSION="${DNGLAB_VERSION:-v0.8.0}"
DEST="${1:-$HOME/.local/bin}"
mkdir -p "$DEST"

uname_s="$(uname -s)"
uname_m="$(uname -m)"

asset=""
case "$uname_s-$uname_m" in
  Linux-x86_64)  asset="dnglab_linux_x64" ;;
  Linux-aarch64) asset="dnglab_linux_aarch64" ;;
  Darwin-arm64)  asset="dnglab-macos-arm64_${VERSION}.zip" ;;
  Darwin-x86_64)
    echo "macOS Intel용 공식 바이너리가 없을 수 있습니다. https://github.com/dnglab/dnglab/releases 를 확인하세요." >&2
    exit 1
    ;;
  *)
    echo "지원하지 않는 플랫폼: $uname_s $uname_m" >&2
    exit 1
    ;;
esac

base="https://github.com/dnglab/dnglab/releases/download/${VERSION}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Downloading $asset ..."
curl -fsSL -o "$tmp/$asset" "$base/$asset"

if [[ "$asset" == *.zip ]]; then
  unzip -q "$tmp/$asset" -d "$tmp/out"
  bin="$(find "$tmp/out" -type f -name 'dnglab*' | head -n1)"
  install -m 755 "$bin" "$DEST/dnglab"
else
  install -m 755 "$tmp/$asset" "$DEST/dnglab"
fi

echo "Installed: $DEST/dnglab"
"$DEST/dnglab" --version
