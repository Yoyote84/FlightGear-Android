#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$ROOT/native/dependencies.lock"

fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -f "$MANIFEST" ]] || fail "missing native/dependencies.lock"

python3 - "$MANIFEST" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
required = ("flightgear", "simgear", "openscenegraph")
for name in required:
    if f"[{name}]" not in text:
        raise SystemExit(f"missing [{name}] entry")

section = None
seen = set()
for raw in text.splitlines():
    line = raw.strip()
    if not line or line.startswith("#"):
        continue
    if line.startswith("[") and line.endswith("]"):
        section = line[1:-1]
        continue
    if "=" not in line:
        raise SystemExit(f"malformed manifest line: {line}")
    key, value = [part.strip() for part in line.split("=", 1)]
    if section in required and key in {"revision", "checksum"}:
        if not value or value == "REPLACE_ME":
            raise SystemExit(f"immutable {key} is missing in [{section}]")
        if key == "revision" and not re.fullmatch(r"[0-9a-f]{40}", value):
            raise SystemExit(f"revision must be a 40-character lowercase Git SHA in [{section}]")
        if key == "checksum" and not re.fullmatch(r"sha1:[0-9a-f]{40}", value):
            raise SystemExit(f"checksum must pin the Git object SHA in [{section}]")
        seen.add((section, key))

for name in required:
    for key in ("revision", "checksum"):
        if (name, key) not in seen:
            raise SystemExit(f"missing {key} in [{name}]")

print("PASS: native dependency manifest is structurally complete")
PY
