#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ABI="arm64-v8a"
OUT="$ROOT/native/out/$ABI"
BUILD="$ROOT/native/build/$ABI"
PREFIX="$OUT/prefix"
TOOLCHAIN="$ROOT/native/cmake/toolchain-android-arm64.cmake"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"

log_stage() { echo; echo "========== $* =========="; }
fail() { echo "FAIL: $*" >&2; exit 1; }

command -v cmake >/dev/null 2>&1 || fail "cmake is required"
command -v ninja >/dev/null 2>&1 || fail "ninja is required"
command -v git >/dev/null 2>&1 || fail "git is required"

[[ -f "$ROOT/native/dependencies.lock" ]] || fail "dependency manifest is missing"
[[ -f "$TOOLCHAIN" ]] || fail "Android ARM64 toolchain file is missing"

log_stage "verify manifest"
bash "$ROOT/native/bootstrap/verify_manifest.sh"

log_stage "fetch pinned sources"
bash "$ROOT/native/bootstrap/fetch_sources.sh"

log_stage "apply native patches"
bash "$ROOT/native/bootstrap/apply_patches.sh"

: "${ANDROID_NDK_ROOT:=${ANDROID_NDK_HOME:-}}"
[[ -n "$ANDROID_NDK_ROOT" ]] || fail "ANDROID_NDK_ROOT/ANDROID_NDK_HOME must point to NDK 27.2.12479018"
[[ -f "$ANDROID_NDK_ROOT/source.properties" ]] || fail "ANDROID_NDK_ROOT does not look like an Android NDK: $ANDROID_NDK_ROOT"

grep -q 'Pkg.Revision = 27.2.12479018' "$ANDROID_NDK_ROOT/source.properties" || fail "expected Android NDK 27.2.12479018"

mkdir -p "$BUILD/osg" "$PREFIX"

log_stage "configure OpenSceneGraph ARM64"
cmake -S "$ROOT/native/src/openscenegraph" -B "$BUILD/osg" -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DFG_NATIVE_PREFIX="$PREFIX" \
  -DCMAKE_PROJECT_INCLUDE="$ROOT/native/cmake/ExternalDependencies.cmake" \
  -DOSG_WINDOWING_SYSTEM=None \
  -DBUILD_OSG_APPLICATIONS=OFF \
  -DBUILD_OSG_EXAMPLES=OFF \
  -DBUILD_OSG_PLUGINS_BY_DEFAULT=OFF \
  -DBUILD_OSG_PLUGIN_PNG=ON \
  -DBUILD_OSG_PLUGIN_JPEG=ON \
  -DBUILD_OSG_PLUGIN_FREETYPE=ON \
  -DDYNAMIC_OPENSCENEGRAPH=ON \
  -DDYNAMIC_OPENTHREADS=ON

log_stage "build OpenSceneGraph ARM64"
cmake --build "$BUILD/osg" --parallel "$JOBS"
cmake --install "$BUILD/osg"

log_stage "verify ARM64 dependency artifacts"
bash "$ROOT/native/test_arm64_artifacts.sh"

log_stage "native dependency stage complete"
echo "PASS: ARM64 OpenSceneGraph dependency stage completed"
