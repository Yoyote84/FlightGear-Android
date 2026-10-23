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

# Boost is used as a header dependency by the native FlightGear/SimGear sources.
# Only headers are needed at this stage, so do not build Boost libraries.
BOOST_VERSION="1.89.0"
BOOST_DIR="$DEPS/boost"
if [ ! -d "$BOOST_DIR/boost" ]; then
  tmp="$DEPS/boost_${BOOST_VERSION}.tar.gz"
  curl -L --fail --retry 3 "https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION//./_}.tar.gz" -o "$tmp"
  tar -xzf "$tmp" -C "$DEPS"
  rm -rf "$BOOST_DIR"
  mv "$DEPS/boost_${BOOST_VERSION//./_}" "$BOOST_DIR"
  rm -f "$tmp"
fi

# The normal desktop build generates these headers from CMake/autoconf.
# The Android build deliberately has no desktop configure pass, so provide
# the small platform configuration headers required by the upstream sources.
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

mkdir -p "$DEPS/simgear/simgear"
cat > "$DEPS/simgear/simgear/simgear_config.h" <<'EOF'
#pragma once
#define SIMGEAR_VERSION_MAJOR 2026
#define SIMGEAR_VERSION_MINOR 0
#define SIMGEAR_VERSION_PATCH 0
#define SIMGEAR_HAVE_OPENGL 1
#define SIMGEAR_HAVE_OPENGL_ES 1
#define SG_HAVE_DDS 0
#define SG_FFMPEG 0
#define SG_SOUND_USES_OPENALSOFT 0
#define HAVE_WORKING_STD_REGEX 1
#define GCC_ATOMIC_BUILTINS_FOUND 1
#define SIMGEAR_OSG_USE_FG_FORK 1
#define SIMGEAR_OSG_CORRECT_VERSION 1
EOF

mkdir -p "$DEPS/openscenegraph/include/osg" "$DEPS/openscenegraph/include/OpenThreads"
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

cat > "$DEPS/openscenegraph/include/OpenThreads/Config" <<'EOF'
#pragma once
#define OPENTHREADS_VERSION_MAJOR 3
#define OPENTHREADS_VERSION_MINOR 3
#define OPENTHREADS_VERSION_PATCH 0
#define OPENTHREADS_EXPORT
#define OPENTHREADS_EXPORTS 1
#define OPENTHREADS_BUILD_STATIC_LIBS 1
#define OPENTHREADS_USE_PTHREADS 1
#define OPENTHREADS_PLATFORM_ANDROID 1
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
EOF

echo "FlightGear Android native sources prepared under $DEPS"
