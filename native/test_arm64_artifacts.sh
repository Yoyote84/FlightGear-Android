#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${NATIVE_OUT:-$ROOT/native/out/arm64-v8a}"

fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -d "$OUT" ]] || fail "missing native output directory: $OUT"

mapfile -t artifacts < <(find "$OUT" -type f \( -name '*.so' -o -name '*.a' -o -name '*.elf' \) -print | sort)
((${#artifacts[@]} > 0)) || fail "no native ELF artifacts found under $OUT"

for artifact in "${artifacts[@]}"; do
    case "$artifact" in
        *.a) continue ;;
    esac
    machine="$(readelf -h "$artifact" 2>/dev/null | awk -F: '/Machine:/ {gsub(/^[ \t]+/, "", $2); print $2}')"
    [[ "$machine" == "AArch64" ]] || fail "non-AArch64 ELF artifact: $artifact ($machine)"
done

for required in libOpenThreads.so libosg.so; do
    find "$OUT" -type f -name "$required" -print -quit | grep -q . || fail "missing required ARM64 OpenSceneGraph library: $required"
done

echo "PASS: native output contains only accepted ARM64 ELF libraries and required OpenSceneGraph core"
