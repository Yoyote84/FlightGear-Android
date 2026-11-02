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
EOF

python3 - "$DEPS/simgear/simgear/std/type_traits.hxx" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
s = s.replace('#include <type_traits>\n', '#include <type_traits>\n#define HAVE_STD_REMOVE_CV_T 1\n#define HAVE_STD_ENABLE_IF_T 1\n#define HAVE_STD_BOOL_CONSTANT 1\n')
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
#define OPENTHREADS_USE_PTHREADS 1
EOF

mkdir -p "$DEPS/openscenegraph/include/osg"
cat > "$DEPS/openscenegraph/include/osg/Version" <<'EOF'
#pragma once
#define OSG_VERSION_MAJOR 3
#define OSG_VERSION_MINOR 7
#define OSG_VERSION_PATCH 0
#define OSG_VERSION "3.7.0"
EOF

cat > "$DEPS/openscenegraph/include/osg/GL" <<'EOF'
#pragma once
#ifndef GL_APIENTRY
#define GL_APIENTRY APIENTRY
#endif
/* Legacy OpenGL enums referenced by OSG's portable headers. */
#endif
EOF

cat > "$DEPS/openscenegraph/include/osg/GL" <<'EOF'
#pragma once
#ifndef GL_APIENTRY
#define GL_APIENTRY APIENTRY
#endif
/* Legacy OpenGL enums referenced by OSG's portable headers. */
#endif
#ifndef GL_COLOR4F
#define GL_COLOR4F 0x8058
#endif
#ifndef GL_NORMAL3F
#define GL_NORMAL3F 0x8059
#endif
/* Legacy OpenGL fixed-function entry points do not exist in GLES; these are
   compile-time compatibility shims for legacy OSG branches that are disabled
   at runtime. */
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
