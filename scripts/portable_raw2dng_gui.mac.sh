#!/usr/bin/env bash
# macOS GUI helper — file picker via osascript, convert with bundled dnglab
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DNGLAB="$HERE/dnglab"
if [[ ! -x "$DNGLAB" ]]; then
  osascript -e 'display alert "raw2dng" message "dnglab not found next to this app."'
  exit 2
fi
files=$(osascript <<'APPLESCRIPT'
set theFiles to choose file with prompt "RAW 파일 선택" with multiple selections allowed
set out to ""
repeat with f in theFiles
  set out to out & POSIX path of f & linefeed
end repeat
return out
APPLESCRIPT
) || exit 1

ok=0; fail=0
while IFS= read -r inp; do
  [[ -z "$inp" ]] && continue
  out="${inp%.*}.dng"
  if "$DNGLAB" convert -f "$inp" "$out"; then ok=$((ok+1)); else fail=$((fail+1)); fi
done <<< "$files"
osascript -e "display alert \"raw2dng\" message \"완료 — 성공 $ok, 실패 $fail\""
