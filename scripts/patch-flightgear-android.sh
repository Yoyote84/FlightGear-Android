#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEPS="$ROOT/third_party"
FG="$DEPS/flightgear"
OSG="$DEPS/openscenegraph"

# Android config values expected by upstream FlightGear sources.
python3 - "$FG/src/config.h" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
insert = {
    '#define FG_BUILD_TYPE "Debug"': 'FG_BUILD_TYPE',
    '#define WEB_BROWSER ""': 'WEB_BROWSER',
    '#define VERSION "2024.2.0"': 'VERSION',
}
for line, key in insert.items():
    if key not in s:
        s += line + "\n"
p.write_text(s)
PY

# Generate the build-id header normally produced by FlightGear CMake.
mkdir -p "$FG/src/Include"
cat > "$FG/src/Include/flightgearBuildId.h" <<'EOF'
#pragma once
#define BUILD_DATE "2026-10-23"
#define REVISION "android"
EOF
cp "$FG/src/Include/flightgearBuildId.h" "$FG/src/flightgearBuildId.h"

# Android has no audio backend in this build. Fix the upstream dummy subsystem
# declaration; the upstream file currently has the override specifier after
# the function body, which is invalid C++.
python3 - "$FG/src/Sound/soundmanager.hxx" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
s = s.replace('void update(double dt) {} override', 'void update(double dt) override {}')
p.write_text(s)
PY

# Enable OSG's intended implicit ref_ptr -> raw pointer output conversion.
# This is the compatibility mode specifically designed for APIs returning T*.
python3 - "$OSG/include/osg/Config" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
line = '#define OSG_USE_REF_PTR_IMPLICIT_OUTPUT_CONVERSION 1'
if line not in s:
    s += "\n" + line + "\n"
p.write_text(s)
PY

# Also expose the generated FlightGear Include directory to the native target.
# CMake is patched here rather than modifying upstream FlightGear sources.
python3 "$ROOT/scripts/patch-flightgear-cmake.py"

echo "FlightGear Android compatibility patches applied"
