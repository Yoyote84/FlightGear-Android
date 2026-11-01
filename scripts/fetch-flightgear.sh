#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEPS="$ROOT/third_party"
mkdir -p "$DEPS"

clone_or_update() {
  local url="$1"
  local dir="$2"
  local ref="$3"
  if [ -d "$DEPS/$dir/.git" ]; then
    git -C "$DEPS/$dir" fetch --depth=1 origin "$ref"
    git -C "$DEPS/$dir" checkout -q FETCH_HEAD
  else
    git clone --depth=1 --branch "$ref" "$url" "$DEPS/$dir"
  fi
}

# FlightGear's actively maintained mirrors.
clone_or_update "https://github.com/FlightGear/simgear.git" "simgear" "next"
clone_or_update "https://github.com/FlightGear/flightgear.git" "flightgear" "next"
clone_or_update "https://gitlab.com/flightgear/openscenegraph.git" "openscenegraph" "next"

# The current FlightGear 'next' branch contains a small syntax error in the
# Android-reachable dummy audio subsystem: the C++11 override specifier is
# placed after the function body. Keep the upstream source intact in Git and
# apply this deterministic Android build patch only to the fetched worktree.
python3 - "$DEPS/flightgear/src/Sound/soundmanager.hxx" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
old = '    void update(double dt) {} override\n'
new = '    void update(double dt) override {}\n'
if old in text:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
elif new not in text:
    raise SystemExit("Unexpected FlightGear soundmanager.hxx: Android compatibility patch did not match")
PY

echo "FlightGear Android native sources prepared under $DEPS"
