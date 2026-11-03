#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEPS="$ROOT/third_party"
BUILD_ROOT="$ROOT/.android-deps/curl"
CURL_VERSION="8.17.0"
ARCHIVE="$BUILD_ROOT/curl.tar.xz"
SRC="$BUILD_ROOT/curl-${CURL_VERSION}"
PREFIX="$BUILD_ROOT/prefix"

mkdir -p "$BUILD_ROOT"
if [ ! -d "$SRC" ]; then
  curl -L --fail --retry 3 "https://curl.se/download/curl-${CURL_VERSION}.tar.xz" -o "$ARCHIVE"
  tar -xJf "$ARCHIVE" -C "$BUILD_ROOT"
fi

NDK="${ANDROID_NDK_HOME:-${ANDROID_HOME}/ndk/27.2.12479018}"
TOOLCHAIN="$NDK/build/cmake/android.toolchain.cmake"
if [ ! -f "$TOOLCHAIN" ]; then
  echo "Android NDK toolchain not found: $TOOLCHAIN" >&2
  exit 1
fi

rm -rf "$BUILD_ROOT/build" "$PREFIX"
cmake -S "$SRC" -B "$BUILD_ROOT/build" \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-26 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_CURL_EXE=OFF \
  -DBUILD_TESTING=OFF \
  -DCURL_USE_OPENSSL=OFF \
  -DCURL_USE_ZLIB=OFF \
  -DCURL_USE_LIBPSL=OFF \
  -DCURL_USE_LIBSSH2=OFF \
  -DCURL_DISABLE_LDAP=ON \
  -DCURL_DISABLE_LDAPS=ON \
  -DCURL_DISABLE_RTSP=ON \
  -DCURL_DISABLE_DICT=ON \
  -DCURL_DISABLE_TELNET=ON \
  -DCURL_DISABLE_TFTP=ON \
  -DCURL_DISABLE_GOPHER=ON \
  -DCURL_DISABLE_IMAP=ON \
  -DCURL_DISABLE_POP3=ON \
  -DCURL_DISABLE_SMTP=ON \
  -DCURL_DISABLE_SMB=ON \
  -DCURL_DISABLE_MQTT=ON \
  -DCURL_DISABLE_FTP=ON \
  -DCURL_DISABLE_FILE=OFF \
  -DCURL_DISABLE_HTTP=OFF
cmake --build "$BUILD_ROOT/build" --parallel
cmake --install "$BUILD_ROOT/build" --prefix "$PREFIX"

echo "Android ARM64 libcurl prepared at $PREFIX"
