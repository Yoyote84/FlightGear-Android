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
    '#define FG_HAVE_HLA 0': 'FG_HAVE_HLA',
    '#define PKGLIBDIR "."': 'PKGLIBDIR',
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

# FlightGear options.cxx uses osgGetVersion() without including the OSG
# declaration on this Android build. Add the official OSG Version header.
python3 - "$FG/src/Main/options.cxx" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
needle = '#include <config.h>\n'
addition = '#include <osg/Version>\n'
if addition not in s:
    if needle not in s:
        raise SystemExit('options.cxx config include not found')
    s = s.replace(needle, needle + addition, 1)
p.write_text(s)
PY

# The generated OSG Version header must expose osgGetVersion() as well as
# version constants; Version.cpp is already part of the OSG source glob.
python3 - "$OSG/include/osg/Version" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
line = 'extern "C" const char* osgGetVersion();'
if line not in s:
    s += "\n" + line + "\n"
p.write_text(s)
PY

# Enable OSG's intended implicit ref_ptr -> raw pointer output conversion.
python3 - "$OSG/include/osg/Config" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
lines = [
    '#define OSG_USE_REF_PTR_IMPLICIT_OUTPUT_CONVERSION 1',
    '#ifndef OSG_EXPORT',
    '#define OSG_EXPORT',
    '#endif',
]
for line in lines:
    if line not in s:
        s += "\n" + line
s += "\n"
p.write_text(s)
PY

# Also expose the generated FlightGear Include directory to the native target.
python3 "$ROOT/scripts/patch-flightgear-cmake.py"

echo "FlightGear Android compatibility patches applied (OSG_EXPORT fixed)"
