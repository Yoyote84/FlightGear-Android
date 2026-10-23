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
#define FG_HAVE_GPERFTOOLS 0
#define FLIGHTGEAR_VERSION "2024.2.0"
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

# Android NDK libc++ already provides most C++17 type aliases used by SimGear.
mkdir -p "$DEPS/simgear/simgear"
cat > "$DEPS/simgear/simgear/simgear_config.h" <<'EOF'
#pragma once
#define SIMGEAR_ANDROID 1
#define SIMGEAR_HAVE_OPENGL 1
#define SIMGEAR_HAVE_OPENGL_ES 1
#define HAVE_STD_REMOVE_CV_T 1
#define HAVE_STD_ENABLE_IF_T 1
#define HAVE_STD_BOOL_CONSTANT 1
/* libc++ in the Android NDK is C++17 here; provide remove_cvref_t below. */
EOF

python3 - "$DEPS/simgear/simgear/std/type_traits.hxx" <<'PY'
from pathlib import Path
p = Path(__import__('sys').argv[1])
s = p.read_text()
marker = '#include <type_traits>\n'
if 'SG_ANDROID_REMOVE_CVREF_COMPAT' not in s:
    s = s.replace(marker, marker + '''\n#if defined(ANDROID) && !defined(SG_ANDROID_REMOVE_CVREF_COMPAT)\n#define SG_ANDROID_REMOVE_CVREF_COMPAT 1\nnamespace std {\ntemplate<class T> using remove_cvref_t = remove_cv_t<remove_reference_t<T>>;\n}\n#endif\n''')
p.write_text(s)
PY

# SimGear's legacy integer_sequence compatibility predates the C++17 implementation
# shipped by Android libc++. On Android use the standard implementation and retain only
# the append helper that SimGear needs.
python3 - "$DEPS/simgear/simgear/std/integer_sequence.hxx" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
if 'SG_ANDROID_INTEGER_SEQUENCE_COMPAT' not in s:
    original = s
    replacement = '''#pragma once\n\n#if defined(ANDROID)\n#define SG_ANDROID_INTEGER_SEQUENCE_COMPAT 1\n#include <utility>\nnamespace std {\ntemplate<class T, class Seq, T Int> struct append;\ntemplate<class T, T... Ints, T Int>\nstruct append<T, integer_sequence<T, Ints...>, Int> {\n    using type = integer_sequence<T, Ints..., Int>;\n};\n}\n#else\n''' + original + '''\n#endif\n'''
    p.write_text(replacement)
PY

# The OSG fork used by FlightGear has a legacy ref_ptr API. Modern SimGear expects
# the conventional raw-pointer conversion for these accessors.
python3 - "$DEPS/openscenegraph/include/osg/ref_ptr" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
needle = 'operator unspecified_bool_type() const'
if 'SG_ANDROID_REFPTR_RAW_POINTER' not in s and needle in s:
    s = s.replace(needle, '#if defined(ANDROID)\n#define SG_ANDROID_REFPTR_RAW_POINTER 1\noperator T*() const { return _ptr; }\n#endif\n\n' + needle, 1)
p.write_text(s)
PY

mkdir -p "$DEPS/openscenegraph/include/OpenThreads"
cat > "$DEPS/openscenegraph/include/OpenThreads/Config" <<'EOF'
#pragma once
#define OPENTHREADS_VERSION 200000
#define OPENTHREADS_VERSION_MAJOR 2
#define OPENTHREADS_VERSION_MINOR 0
#define OPENTHREADS_VERSION_PATCH 0
#define OPENTHREADS_EXPORT
#define OPENTHREADS_EXPORTS 1
#define OPENTHREADS_PLATFORM_ANDROID 1
#define OPENTHREADS_USE_PTHREADS 1
EOF

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