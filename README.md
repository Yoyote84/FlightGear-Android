# FlightGear Android

A native Android port of the original FlightGear flight simulator for ARM64
devices.

## Primary device target

- Samsung Galaxy Z Flip6
- Android 16 / API 36 target (stable)
- `arm64-v8a` native ABI
- OpenGL ES 3.0 graphics through EGL
- Landscape-first full-screen flight-simulator interface
- Native FlightGear, SimGear, and FlightGear's OpenSceneGraph fork

The goal is to run the original FlightGear engine on-device. This is not a
remote-control client, streaming client, browser wrapper, or reimplementation.

## Build foundation

The project pins its Android build toolchain in Gradle and uses the Android
NDK r30 LTS, CMake, and C++17. The CI workflow builds an ARM64 debug APK,
checks for the FlightGear native engine symbol, and checks 16 KB ELF alignment
before publishing an APK artifact.

See [Android build setup](docs/ANDROID_BUILD_SETUP.md) for exact versions,
dependencies, and local build commands.

## Port status

The Android app shell, JNI surface bridge, EGL setup, and native source build
graph are in place. The FlightGear C++ sources are being adapted and linked;
the simulator startup sequence, aircraft/data packaging, input controls,
scenery, and runtime validation are not yet complete.

A successful APK build is not considered a finished simulator until the
FlightGear engine starts, the C172P can load, and the app has been tested on
the Galaxy Z Flip6 in both folded and unfolded states.
