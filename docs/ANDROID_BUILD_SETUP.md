# Android build setup

This document records the toolchain, device assumptions, and native checks for
the `native-flightgear-port` branch.

## Device and platform target

| Item | Configuration |
|---|---|
| Device target | Samsung Galaxy Z Flip6 |
| CPU ABI | `arm64-v8a` |
| Minimum Android API | 26 |
| Compile / target API | 36 (Android 16 stable) |
| Graphics API | OpenGL ES 3.0 via EGL |
| Native language standard | C++17 |
| Display mode | immersive full-screen, landscape-first, resizable |

The app targets API 36 (the stable SDK platform available to this build) and
declares the game category because FlightGear is a flight simulator. This
keeps landscape-first behavior for a game while still handling surface changes
when the Z Flip6 is folded or unfolded. Android 17 / API 37 remains a preview
SDK in the current Android SDK distribution, so it is not used as the release
build target yet.

## Build toolchain

| Tool | Pinned version |
|---|---|
| Java runtime | 17 |
| Java source / bytecode compatibility | 17 |
| Android Gradle Plugin | 9.5.0 |
| Gradle | 9.6.0 |
| Android NDK | 30.0.16248370 (r30 LTS) |
| CMake | 3.22.1 |
| Android SDK platform | 36 |
| Android Build Tools | 36.0.0 |

Java source and bytecode compatibility are explicitly pinned to Java 17 to match the CI JDK and the Android Gradle Plugin requirement. The NDK r30 toolchain produces 16 KB-aligned native libraries by default. The project also passes explicit ELF linker alignment options and checks the produced native libraries with `scripts/test-16kb-page-size.sh`.

The CI workflow verifies that the exact SDK platform, Build Tools, NDK revision, CMake binary, and compiler are installed before configuring the Android Gradle project. It runs `:app:help` as a separate configuration check, so Gradle/AGP configuration failures are distinguishable from native compilation and linking failures.

## Native dependencies

`scripts/fetch-flightgear.sh` initializes the FlightGear, SimGear, and FlightGear
OpenSceneGraph submodules at the exact commits pinned in this repository, then
prepares their Android compatibility worktrees and downloads Boost 1.89.0 headers. It applies targeted compatibility
adjustments to the fetched worktrees, including the explicit Boost.MPL include
needed by SimGear's Nasal hash wrapper.

`scripts/build-curl-android.sh` builds static ARM64 libcurl 8.17.0 using the
pinned Android NDK. CMake expects the result under
`.android-deps/curl/prefix`.

## Build sequence

Run from the repository root with JDK 17, Android SDK platform 36, Android NDK
30.0.16248370, CMake 3.22.1, and Gradle 9.6.0 available:

```bash
chmod +x scripts/fetch-flightgear.sh scripts/build-curl-android.sh
./scripts/fetch-flightgear.sh
./scripts/build-curl-android.sh
gradle --no-daemon :app:assembleDebug
```

After compilation, verify the native FlightGear symbol and 16 KB ELF alignment:

```bash
chmod +x scripts/test-native-engine-symbol.sh scripts/test-16kb-page-size.sh
scripts/test-native-engine-symbol.sh \
  app/build/intermediates/stripped_native_libs/debug/out/lib/arm64-v8a/libflightgear_android.so
scripts/test-16kb-page-size.sh \
  app/build/intermediates/stripped_native_libs/debug/out/lib/arm64-v8a
```

The GitHub Actions workflow `.github/workflows/android.yml` performs the same
sequence and publishes the debug APK only after both native checks pass.

## Current implementation boundary

The Android shell, JNI bridge, surface management, EGL setup, ARM64 toolchain,
and dependency acquisition are present. The current bridge manages the graphics
surface but does not yet start FlightGear's simulator subsystems or execute the
simulation/render loop. A successful native library link alone is therefore
not proof of a working simulator.

The latest inspected build (run 44973487217, 22 Nov 2026) passed JDK setup,
Android SDK package installation, FlightGear source preparation, libcurl
compilation, and Gradle installation. C++ compilation completed and the final
native link was reached; it then failed on unresolved implementation symbols
from OpenSceneGraph, FlightGear GUI/viewer code, and Nasal. No APK artifact was
produced. This is a Step 3 native source/link integration blocker, not an
Android SDK, NDK, CMake, or Gradle toolchain setup failure.
