# FlightGear Android

Native Android port of the real FlightGear flight simulator for ARM64 devices.

## Target
- Samsung Galaxy Z Flip6
- Android / arm64-v8a
- Native FlightGear C++ engine
- SimGear
- FlightGear OpenSceneGraph fork
- Android NDK + CMake

## Status
V0.1 — Android build foundation.

The goal is to run the original FlightGear engine natively on Android, not a remote-control client, emulator, streaming client, or reimplementation.

## Planned stages
1. Android application and native/JNI bridge
2. OpenGL ES Android graphics surface
3. FlightGear + SimGear native ARM64 build
4. FlightGear data and C172P
5. Touch controls and camera
6. Audio, weather and scenery
7. Z Flip6 performance tuning
