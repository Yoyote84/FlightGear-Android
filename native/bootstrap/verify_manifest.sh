#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$ROOT/native/dependencies.lock"

fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -f "$MANIFEST" ]] || fail "missing native/dependencies.lock"

python3 - "$MANIFEST" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
required = ("flightgear", "simgear", "openscenegraph")
for name in required:
    if f"[{name}]" not in text:
        raise SystemExit(f"missing [{name}] entry")

for line in text.splitlines():
    line = line.strip()
    if not line or line.startswith("#") or line.startswith("["):
        continue
    if "=" not in line:
        raise SystemExit(f"malformed manifest line: {line}")
    key, value = [part.strip() for part in line.split("=", 1)]
    if key in {"revision", "sha256"} and value in {"", "REPLACE_ME"}:
        raise SystemExit(f"immutable {key} is missing")

print("PASS: native dependency manifest is structurally complete")
PY
