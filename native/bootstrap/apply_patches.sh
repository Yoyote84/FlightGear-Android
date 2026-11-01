#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PATCH_ROOT="$ROOT/native/patches"
SOURCE_ROOT="${SOURCE_ROOT:-$ROOT/native/src}"

fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -d "$PATCH_ROOT" ]] || fail "missing native/patches"

# Patches are deliberately applied as a separate stage so source acquisition
# remains reproducible and failures identify the exact convergence boundary.
shopt -s nullglob
patches=("$PATCH_ROOT"/*.patch)
if ((${#patches[@]} == 0)); then
    echo "PASS: no native source patches are required for the pinned baseline"
    exit 0
fi

for patch_file in "${patches[@]}"; do
    echo "Applying $(basename "$patch_file")"
    patch -p1 -d "$SOURCE_ROOT" < "$patch_file"
done

echo "PASS: native source patches applied"
