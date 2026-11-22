# Android build setup

This document records the Android toolchain and native prerequisites used by
the `native-flightgear-port` branch.

## Target configuration

| Item | Configuration |
|---|---|
| Device target | Samsung Galaxy Z Flip6 |
| Android ABI | `arm64-v8a` only |
| Minimum Android API | 26 |
| Compile / target API | 36 |
| Android Gradle Plugin | 8.13.2 |
| Gradle | 8.13 (CI) |
| Java | 17 |
| Android NDK | 27.2.12479018 |
| CMake | 3.22.1 |
| Native language standard | C++17 |
| Graphics API | OpenGL ES 3.0 via EGL |

The manifest, EGL context, and OpenSceneGraph configuration must agree on
OpenGL ES 3.0. Do not lower one layer to ES 2.0 without changing and testing
the complete native graphics configuration.

## Native dependencies

`scripts/fetch-flightgear.sh` retrieves FlightGear, SimGear, the FlightGear
OpenSceneGraph fork, and Boost headers. The script also applies the documented
Android compatibility adjustments to the fetched worktrees.

`scripts/build-curl-android.sh` builds static ARM64 libcurl 8.17.0 with the
Android NDK. CMake expects the result under `.android-deps/curl/prefix`.

## Build sequence

Run from the repository root in an environment with JDK 17, Android SDK,
Android NDK 27.2.12479018, CMake 3.22.1, and Gradle 8.13 available:

```bash
chmod +x scripts/fetch-flightgear.sh scripts/build-curl-android.sh
./scripts/fetch-flightgear.sh
./scripts/build-curl-android.sh
gradle --no-daemon :app:assembleDebug
```

After the APK has been built, verify that the native library contains the
FlightGear engine entry point:

```bash
chmod +x scripts/test-native-engine-symbol.sh
scripts/test-native-engine-symbol.sh \
  app/build/intermediates/stripped_native_libs/debug/out/lib/arm64-v8a/libflightgear_android.so
```

The GitHub Actions workflow `.github/workflows/android.yml` performs the same
sequence and publishes the debug APK only after the native symbol check passes.

## Current boundary

This setup stage prepares the Android shell, ABI, graphics context, toolchain,
and dependency acquisition. It does not mean the FlightGear engine is already
fully linked or running.

The last inspected CI run before these setup changes (run 41998892874, 5 Nov
2026) reached the native link step and failed on unresolved FlightGear and
OpenSceneGraph symbols. Those engine-link errors belong to the next native
integration/build stage and must be cleared before an APK can be considered
usable.
