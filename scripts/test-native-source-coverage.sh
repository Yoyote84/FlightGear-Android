#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FG="$ROOT/third_party/flightgear"
SG="$ROOT/third_party/simgear"
OSG="$ROOT/third_party/openscenegraph"
SOURCES="$ROOT/app/src/main/cpp/flightgear_main_sources.cmake"
CMAKE="$ROOT/app/src/main/cpp/CMakeLists.txt"

failures=0
require_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "MISSING upstream implementation file: $file" >&2
    failures=$((failures + 1))
  fi
}
require_cmake_source() {
  local relative="$1"
  local needle="${relative}"
  if ! grep -Fq "$needle" "$SOURCES"; then
    echo "NOT LINKED from FlightGear source set: $relative" >&2
    failures=$((failures + 1))
  fi
}
require_nasal_source() {
  local name="$1"
  require_file "$SG/simgear/nasal/$name"
  if ! grep -Fq "$name" "$CMAKE"; then
    echo "Nasal implementation is not included in CMake: $name" >&2
    failures=$((failures + 1))
  fi
}

# The implementations named below are pinned by the repository's gitlinks.
# Verify both the on-disk upstream file and its inclusion in the Android link.
for item in \
  "src/osg/OperationThread.cpp" \
  "src/osg/GraphicsThread.cpp" \
  "src/osg/View.cpp"; do
  require_file "$OSG/$item"
  require_cmake_source "${item##*/}"
done

for item in \
  "src/Viewer/CameraGroup.cxx" \
  "src/Viewer/WindowSystemAdapter.cxx" \
  "src/Viewer/fg_os_osgviewer.cxx" \
  "src/GUI/MouseCursor.cxx"; do
  require_file "$FG/$item"
  require_cmake_source "$item"
done

for item in \
  bitslib.c code.c codegen.c gc.c hash.c iolib.c lex.c lib.c \
  mathlib.c misc.c parse.c string.c thread-posix.c threadlib.c \
  utf8lib.c vector.c unixlib.c NasalEmesaryInterface.cxx; do
  require_nasal_source "$item"
done

if ! grep -Fq "add_library(simgear_nasal_objects OBJECT" "$CMAKE"; then
  echo "Nasal object target is missing from CMake" >&2
  failures=$((failures + 1))
fi
if ! grep -Fq "simgear_nasal_objects" "$CMAKE"; then
  echo "Nasal objects are not linked into flightgear_android" >&2
  failures=$((failures + 1))
fi

if (( failures > 0 )); then
  echo "Native source coverage failed with $failures missing integration item(s)." >&2
  exit 1
fi

echo "Pinned FlightGear, OpenSceneGraph, and Nasal source coverage verified."
