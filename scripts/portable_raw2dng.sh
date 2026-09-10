#!/usr/bin/env bash
# Portable raw2dng — no Python. Expects ./dnglab beside this script.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DNGLAB="${RAW2DNG_DNGLAB:-${DNGLAB:-$HERE/dnglab}}"

usage() {
  cat >&2 <<'USAGE'
Usage:
  raw2dng <input.RAW> [output.dng]
  raw2dng <input_dir> <output_dir>
  raw2dng a.RAW b.RAW <output_dir>
  raw2dng -r <input_dir> <output_dir>
  raw2dng -f ...
  raw2dng -V
USAGE
}

if [[ $# -lt 1 ]]; then usage; exit 1; fi
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  -V|--version) echo "raw2dng 0.1.1 (portable)"; exit 0 ;;
esac

if [[ ! -e "$DNGLAB" ]]; then
  echo "dnglab not found next to raw2dng. Re-download the release package." >&2
  exit 2
fi

force=0
recursive=0
args=()
for a in "$@"; do
  case "$a" in
    -f) force=1 ;;
    -r) recursive=1 ;;
    -*) echo "unknown option: $a" >&2; usage; exit 1 ;;
    *) args+=("$a") ;;
  esac
done

if [[ ${#args[@]} -lt 1 ]]; then usage; exit 1; fi

run_one() {
  local inp="$1" out="$2"
  local cmd=("$DNGLAB" convert)
  [[ "$force" -eq 1 ]] && cmd+=(-f)
  cmd+=("$inp" "$out")
  echo "$(basename "$inp") → $out"
  "${cmd[@]}"
}

if [[ ${#args[@]} -eq 1 ]]; then
  inp="${args[0]}"
  if [[ -d "$inp" ]]; then
    echo "폴더 변환 시 출력 폴더 필요: raw2dng <in_dir> <out_dir>" >&2
    exit 1
  fi
  out="${inp%.*}.dng"
  run_one "$inp" "$out"
  exit $?
fi

out="${args[-1]}"
inputs=("${args[@]:0:${#args[@]}-1}")

if [[ ${#inputs[@]} -eq 1 && -d "${inputs[0]}" ]]; then
  mkdir -p "$out"
  cmd=("$DNGLAB" convert)
  [[ "$force" -eq 1 ]] && cmd+=(-f)
  [[ "$recursive" -eq 1 ]] && cmd+=(-r)
  cmd+=("${inputs[0]}" "$out")
  exec "${cmd[@]}"
fi

mkdir -p "$out"
rc=0
for inp in "${inputs[@]}"; do
  base="$(basename "$inp")"
  stem="${base%.*}"
  dest="$out/$stem.dng"
  if ! run_one "$inp" "$dest"; then rc=$?; fi
done
exit "$rc"
