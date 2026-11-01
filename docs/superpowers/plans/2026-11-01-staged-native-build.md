# Staged Native Android Build Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Split the ARM64 Android port into independently validated OSG, SimGear, FlightGear and final APK gates while reusing native build state.

**Architecture:** GitHub Actions reusable workflows provide separate gates. The orchestrator runs OSG, then SimGear, then FlightGear, then the complete APK build. Each native gate configures CMake and builds only its relevant target; `.cxx` is cached per commit between gates.

**Tech Stack:** GitHub Actions, Gradle 8.13, Android SDK/NDK 27.2.12479018, CMake 3.22.1, C++17, ARM64 Android.

**Spec:** Confirmed by user on 2026-11-01.

## Global Constraints
- ABI remains `arm64-v8a`.
- Upstream FlightGear/SimGear/OpenSceneGraph remain source of truth.
- No Box64/emulation.
- A gate is green only after its real CMake target succeeds.
- Only the final integration gate may claim an installable APK.

## Review Focus
- OSG GLES1 handling remains correct.
- SimGear uses the same commit-scoped native state as OSG.
- FlightGear source compilation is real, not configuration-only.
- Cache keys cannot cross commits.
- Final APK still builds the complete graph.

### Tasks
- [ ] Add `.github/workflows/gate-osg.yml` for `FGOpenSceneGraph`.
- [ ] Add `.github/workflows/gate-simgear.yml` for `SimGearCore` and `SimGearScene`.
- [ ] Add `.github/workflows/gate-flightgear.yml` for `flightgear_main_objects`.
- [ ] Convert `.github/workflows/android.yml` into the orchestrator/final integration gate.
- [ ] Verify ordering, cache reuse and final APK artifact in GitHub Actions.
