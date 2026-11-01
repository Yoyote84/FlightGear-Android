#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_ROOT="${SOURCE_ROOT:-$ROOT/native/src}"
STAMP="${SOURCE_STAMP:-$ROOT/native/build/source-stamp.txt}"

fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -f "$ROOT/native/bootstrap/fetch_sources.sh" ]] || fail "missing fetch_sources.sh"
[[ -f "$ROOT/native/bootstrap/apply_patches.sh" ]] || fail "missing apply_patches.sh"

for project in flightgear simgear openscenegraph; do
    [[ -d "$SOURCE_ROOT/$project" ]] || fail "missing source tree: $SOURCE_ROOT/$project"
done

[[ -f "$STAMP" ]] || fail "missing source stamp: $STAMP"

python3 - "$ROOT/native/dependencies.lock" "$STAMP" <<'PY'
import sys
from pathlib import Path

manifest = Path(sys.argv[1]).read_text(encoding="utf-8")
stamp = Path(sys.argv[2]).read_text(encoding="utf-8")
for project in ("flightgear", "simgear", "openscenegraph"):
    section = manifest.split(f"[{project}]", 1)[1].split("[", 1)[0]
    revision = next(line.split("=", 1)[1].strip() for line in section.splitlines() if line.startswith("revision ="))
    if f"{project}={revision}" not in stamp:
        raise SystemExit(f"stamp does not record pinned revision for {project}")
print("PASS: pinned native source trees and source stamp are present")
PY
