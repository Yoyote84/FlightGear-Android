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

# Enable OSG's intended implicit ref_ptr -> raw pointer output conversion and
# expose the version feature-test macro expected by current SimGear sources.
python3 - "$OSG/include/osg/Config" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
lines = [
    '#define OSG_USE_REF_PTR_IMPLICIT_OUTPUT_CONVERSION 1',
    '#define OSG_MIN_VERSION_REQUIRED(MAJOR, MINOR, PATCH) 1',
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

# ShaderVG is written against desktop GL headers. Android's NDK exposes GLES3,
# so provide the small compatibility facade needed to compile ShaderVG and the
# OSG fixed-function enum names referenced by SimGear. Runtime rendering still
# goes through the existing GLES/EGL path.
mkdir -p "$DEPS/GL"
cat > "$DEPS/GL/glcorearb.h" <<'EOF'
#pragma once
#include <GLES3/gl3.h>
#ifndef GL_AMBIENT
#define GL_AMBIENT 0x1200
#endif
#ifndef GL_DIFFUSE
#define GL_DIFFUSE 0x1201
#endif
#ifndef GL_SPECULAR
#define GL_SPECULAR 0x1202
#endif
#ifndef GL_POSITION
#define GL_POSITION 0x1203
#endif
#ifndef GL_EMISSION
#define GL_EMISSION 0x1600
#endif
#ifndef GL_SHININESS
#define GL_SHININESS 0x1601
#endif
#ifndef GL_AMBIENT_AND_DIFFUSE
#define GL_AMBIENT_AND_DIFFUSE 0x1602
#endif
#ifndef GL_FLAT
#define GL_FLAT 0x1D00
#endif
#ifndef GL_SMOOTH
#define GL_SMOOTH 0x1D01
#endif
#ifndef GL_LIGHTING
#define GL_LIGHTING 0x0B50
#endif
#ifndef GL_LIGHT0
#define GL_LIGHT0 0x4000
#endif
#ifndef GL_LIGHT1
#define GL_LIGHT1 0x4001
#endif
#ifndef GL_LIGHT2
#define GL_LIGHT2 0x4002
#endif
#ifndef GL_LIGHT3
#define GL_LIGHT3 0x4003
#endif
#ifndef GL_LIGHT4
#define GL_LIGHT4 0x4004
#endif
#ifndef GL_LIGHT5
#define GL_LIGHT5 0x4005
#endif
#ifndef GL_LIGHT6
#define GL_LIGHT6 0x4006
#endif
#ifndef GL_LIGHT7
#define GL_LIGHT7 0x4007
#endif
#ifndef GL_MATRIX_MODE
#define GL_MATRIX_MODE 0x0BA0
#endif
#ifndef GL_MODELVIEW
#define GL_MODELVIEW 0x1700
#endif
#ifndef GL_PROJECTION
#define GL_PROJECTION 0x1701
#endif
#ifndef GL_TEXTURE
#define GL_TEXTURE 0x1702
#endif
#ifndef GL_MODELVIEW_MATRIX
#define GL_MODELVIEW_MATRIX 0x0BA6
#endif
#ifndef GL_PROJECTION_MATRIX
#define GL_PROJECTION_MATRIX 0x0BA7
#endif
#ifndef GL_TEXTURE_MATRIX
#define GL_TEXTURE_MATRIX 0x0BA8
#endif
#ifndef GL_VERTEX_ARRAY
#define GL_VERTEX_ARRAY 0x8074
#endif
#ifndef GL_NORMAL_ARRAY
#define GL_NORMAL_ARRAY 0x8075
#endif
#ifndef GL_COLOR_ARRAY
#define GL_COLOR_ARRAY 0x8076
#endif
#ifndef GL_TEXTURE_COORD_ARRAY
#define GL_TEXTURE_COORD_ARRAY 0x8078
#endif
EOF
python3 - "$OSG/include/osg/GL" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
if not p.exists():
    raise SystemExit('expected OSG GL compatibility header not found')
s = p.read_text()
compat = '#include <GL/glcorearb.h>\n'
if compat not in s:
    s = compat + s
p.write_text(s)
PY

# Also expose the generated FlightGear Include directory to the native target.
python3 "$ROOT/scripts/patch-flightgear-cmake.py"

echo "FlightGear Android compatibility patches applied (OSG_EXPORT + Android GL facade fixed)"
