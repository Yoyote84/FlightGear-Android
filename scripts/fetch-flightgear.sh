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

clone_or_update "https://github.com/FlightGear/simgear.git" "simgear" "next"
clone_or_update "https://github.com/FlightGear/flightgear.git" "flightgear" "next"
clone_or_update "https://gitlab.com/flightgear/openscenegraph.git" "openscenegraph" "next"

cat > "$DEPS/flightgear/src/config.h" <<'EOF'
#pragma once
#define HAVE_CONFIG_H 1
#define FG_ANDROID 1
#define ANDROID 1
#define ENABLE_NLS 0
#define ENABLE_SOUND 0
#define ENABLE_JSBSIM 1
#define ENABLE_OPENVR 0
#define ENABLE_VR 0
#define ENABLE_QT 0
#define ENABLE_LARCSIM 0
#define ENABLE_RTI 0
#define ENABLE_DBUS 0
#define ENABLE_METAR 0
#define ENABLE_AI 1
#define HAVE_UNISTD_H 1
#define HAVE_STDINT_H 1
#define HAVE_INTTYPES_H 1
#define HAVE_DLFCN_H 1
#define HAVE_PTHREAD_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_DIRENT_H 1
#define HAVE_MALLOC_H 1
#define HAVE_MEMSET 1
#define HAVE_STRERROR 1
#define HAVE_STRDUP 1
#define HAVE_STRCASECMP 1
#define HAVE_STRNCASECMP 1
EOF

# SimGear's compatibility aliases are only needed on older desktop C++ libraries.
# libc++ in the Android NDK already provides these C++17 aliases.
mkdir -p "$DEPS/simgear/simgear"
python3 - "$DEPS/simgear/simgear/std/type_traits.hxx" <<'PY'
from pathlib import Path
p = Path(__import__('sys').argv[1])
s = p.read_text()
s = s.replace('#include <type_traits>\n', '#include <type_traits>\n#define HAVE_STD_REMOVE_CV_T 1\n#define HAVE_STD_REMOVE_CVREF_T 1\n#define HAVE_STD_ENABLE_IF_T 1\n#define HAVE_STD_BOOL_CONSTANT 1\n')
p.write_text(s)
PY

mkdir -p "$DEPS/openscenegraph/include/osg"
cat > "$DEPS/openscenegraph/include/osg/Config" <<'EOF'
#pragma once
#define OSG_VERSION_MAJOR 3
#define OSG_VERSION_MINOR 7
#define OSG_VERSION_PATCH 0
#define OSG_VERSION "3.7.0"
#define OSG_LIBRARY_STATIC 1
#define OSG_GL1_AVAILABLE 0
#define OSG_GL2_AVAILABLE 1
#define OSG_GL3_AVAILABLE 1
#define OSG_GLES1_AVAILABLE 1
#define OSG_GLES2_AVAILABLE 1
#define OSG_GLES3_AVAILABLE 1
#define OSG_WINDOWING_SYSTEM_NONE 1
#define OSG_GL_DISPLAYLISTS_AVAILABLE 0
#define OSG_GL_MATRICES_AVAILABLE 1
#define OSG_GL_VERTEX_FUNCS_AVAILABLE 1
#define OSG_GL_VERTEX_ARRAY_FUNCS_AVAILABLE 1
#define OSG_GL_FIXED_FUNCTION_AVAILABLE 0
#define OSG_GL_CONTEXT_VERSION "3.0"
EOF

cat > "$DEPS/openscenegraph/include/osg/Version" <<'EOF'
#pragma once
#define OSG_VERSION_MAJOR 3
#define OSG_VERSION_MINOR 7
#define OSG_VERSION_PATCH 0
#define OSG_VERSION "3.7.0"
EOF

cat > "$DEPS/openscenegraph/include/osg/GL" <<'EOF'
#pragma once
#include <cstdint>
#include <GLES3/gl3.h>
#include <GLES3/gl3platform.h>
#include <GLES2/gl2ext.h>
#define OSG_OPENGL 1
#define GL3_PROTOTYPES 1
#define GL_GLEXT_PROTOTYPES 1
#ifndef APIENTRY
#define APIENTRY
#endif
#ifndef GL_APIENTRY
#define GL_APIENTRY APIENTRY
#endif
/* Legacy OpenGL enums referenced by OSG's portable headers. */
#ifndef GL_QUADS
#define GL_QUADS 0x0007
#endif
#ifndef GL_QUAD_STRIP
#define GL_QUAD_STRIP 0x0008
#endif
#ifndef GL_POLYGON
#define GL_POLYGON 0x0009
#endif
#ifndef GL_COMPILE
#define GL_COMPILE 0x1300
#endif
#ifndef GL_DECAL
#define GL_DECAL 0x2101
#endif
#ifndef GL_MODULATE
#define GL_MODULATE 0x2100
#endif
#ifndef GL_ADD
#define GL_ADD 0x0104
#endif
#ifndef GL_DOUBLE
#define GL_DOUBLE 0x140A
#endif
#ifndef GL_NONE
#define GL_NONE 0x0
#endif
#ifndef GL_INT
#define GL_INT 0x1404
#endif
#ifndef GL_UNSIGNED_INT
#define GL_UNSIGNED_INT 0x1405
#endif
#ifndef GL_RGB8_OES
#define GL_RGB8_OES 0x8051
#endif
#ifndef GL_RGBA8_OES
#define GL_RGBA8_OES 0x8058
#endif
/* Fixed-function entry points do not exist in GLES; these are compile-time
   compatibility shims for legacy OSG branches that are disabled at runtime. */
#ifndef glColor4f
static inline void glColor4f(float,float,float,float) {}
#endif
#ifndef glNormal3f
static inline void glNormal3f(float,float,float) {}
#endif
#ifndef glNewList
static inline void glNewList(unsigned int,unsigned int) {}
#endif
#ifndef glEndList
static inline void glEndList() {}
#endif
#ifndef glCallList
static inline void glCallList(unsigned int) {}
#endif
EOF

echo "FlightGear Android native sources prepared under $DEPS"
