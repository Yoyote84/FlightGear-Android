# Full Build Convergence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Converge the Android port from its current JNI/surface foundation into a reproducible ARM64 native FlightGear build pipeline that produces and validates an installable APK.

**Architecture:** Keep the Android app as the thin platform shell and JNI bridge. Build FlightGear, SimGear, and the required graphics/runtime dependencies as native ARM64 libraries/executables through a controlled dependency/bootstrap layer, then package their runtime data with the APK or a verified external data bundle. CI performs the same staged build and publishes the APK plus diagnostic artifacts.

**Tech Stack:** Android Gradle Plugin 8.13.2, Gradle 8.13, Android SDK 36, NDK 27.2.12479018, CMake 3.22.1, C++17, ARM64-v8a, JNI, Android native window APIs, FlightGear, SimGear, OpenSceneGraph.

**Spec:** Repository README target/stages plus the approved Build complet de convergence design.

## Global Constraints

- Target ABI is `arm64-v8a`.
- Minimum Android API is 26; target/compile API is 36.
- The native build uses C++17.
- The product is the original FlightGear engine running natively, not a streaming client, emulator, or reimplementation.
- The convergence pipeline must be reproducible in CI.
- Android surface ownership remains behind the existing JNI bridge.
- FlightGear/SimGear sources must be fetched or pinned in a controlled, reproducible way rather than copied blindly into the Android app module.

## Review Focus

- A clean CI runner must bootstrap every native dependency without relying on developer-local state; test with an empty build cache.
- A partial/native dependency failure must stop the pipeline with a useful stage-specific diagnostic; test each bootstrap stage independently.
- ABI leakage from host/x86 libraries must be rejected; test the final native library set with ELF architecture checks.
- Android surface destruction/recreation must not leave a dangling `ANativeWindow`; test lifecycle transitions around JNI surface callbacks.
- The APK must contain or resolve the exact runtime data version expected by the native engine; test packaging and a clean-install smoke check.

---

### Task 1: Establish reproducible native dependency manifest

**Files:**
- Create: `native/dependencies.lock`
- Create: `native/bootstrap/README.md`
- Test: `native/bootstrap/verify_manifest.sh`

**Interfaces:**
- Produces a version-pinned manifest consumed by all later native bootstrap tasks.

- [ ] **Step 1: Write the failing manifest verification test**
  - Assert required entries exist for FlightGear, SimGear, OpenSceneGraph and their source revisions.
  - Assert every entry has an immutable revision/checksum field.
- [ ] **Step 2: Run the verifier and confirm it fails because the manifest is absent/incomplete.**
- [ ] **Step 3: Implement `native/dependencies.lock` and the shell verifier.**
- [ ] **Step 4: Run `native/bootstrap/verify_manifest.sh` and confirm PASS.**
- [ ] **Step 5: Commit `build: pin native dependency sources`.**

### Task 2: Bootstrap FlightGear/SimGear/OSG sources

**Files:**
- Create: `native/bootstrap/fetch_sources.sh`
- Create: `native/bootstrap/apply_patches.sh`
- Create: `native/patches/README.md`
- Test: `native/bootstrap/test_sources.sh`

**Interfaces:**
- Consumes `native/dependencies.lock`.
- Produces deterministic source trees under `native/src/` and a source stamp under `native/build/source-stamp.txt`.

- [ ] **Step 1: Write source-layout tests for the expected repositories/revisions.**
- [ ] **Step 2: Verify the tests fail on the current repository.**
- [ ] **Step 3: Implement fetching, checksum/revision validation and patch application.**
- [ ] **Step 4: Run the source test on a clean directory.**
- [ ] **Step 5: Commit `build: bootstrap pinned FlightGear sources`.**

### Task 3: Build native third-party dependencies for ARM64

**Files:**
- Create: `native/cmake/toolchain-android-arm64.cmake`
- Create: `native/cmake/ExternalDependencies.cmake`
- Create: `native/build_native.sh`
- Test: `native/test_arm64_artifacts.sh`

**Interfaces:**
- Consumes source trees from Task 2.
- Produces ARM64 native dependency libraries in `native/out/arm64-v8a/`.

- [ ] **Step 1: Write an artifact test that rejects non-ARM64 ELF outputs and missing required libraries.**
- [ ] **Step 2: Confirm the test fails before the native dependency build exists.**
- [ ] **Step 3: Implement the Android CMake toolchain and staged dependency build.**
- [ ] **Step 4: Build with NDK 27.2.12479018 and verify every ELF artifact is AArch64.**
- [ ] **Step 5: Commit `build: add ARM64 native dependency pipeline`.**

### Task 4: Integrate FlightGear and SimGear into the Android native target

**Files:**
- Modify: `app/src/main/cpp/CMakeLists.txt`
- Modify: `app/src/main/cpp/native_bridge.cpp`
- Create: `app/src/main/cpp/flightgear_runtime.h`
- Create: `app/src/main/cpp/flightgear_runtime.cpp`
- Test: `app/src/androidTest/...` for native startup/lifecycle smoke coverage

**Interfaces:**
- Consumes Task 3's native libraries and runtime data contract.
- Produces a JNI-safe runtime controller that owns FlightGear startup/shutdown and receives the Android surface.

- [ ] **Step 1: Add a failing native lifecycle smoke test covering create/start/stop/destroy.**
- [ ] **Step 2: Confirm it fails because FlightGear runtime integration is absent.**
- [ ] **Step 3: Implement the runtime controller with explicit ownership and error propagation.**
- [ ] **Step 4: Wire `MainActivity` JNI callbacks to the runtime controller without changing public lifecycle signatures.**
- [ ] **Step 5: Run native/unit and Android smoke tests.**
- [ ] **Step 6: Commit `feat: integrate native FlightGear runtime`.**

### Task 5: Package FlightGear runtime data and C172P

**Files:**
- Create: `native/runtime/runtime-manifest.lock`
- Create: `native/runtime/package_runtime.sh`
- Modify: `app/build.gradle`
- Test: `native/runtime/test_runtime_package.sh`

**Interfaces:**
- Produces a versioned runtime bundle containing FlightGear base data and C172P assets required for first launch.

- [ ] **Step 1: Write a manifest/package integrity test.**
- [ ] **Step 2: Confirm it fails without packaged runtime data.**
- [ ] **Step 3: Implement deterministic runtime packaging and checksums.**
- [ ] **Step 4: Integrate the bundle into the Android build and verify APK contents.**
- [ ] **Step 5: Commit `build: package FlightGear runtime data`.**

### Task 6: Add controls, camera and Android lifecycle integration

**Files:**
- Create: `app/src/main/java/org/flightgear/android/InputController.java`
- Create: `app/src/main/cpp/input_bridge.cpp`
- Modify: `app/src/main/java/org/flightgear/android/MainActivity.java`
- Test: Android instrumentation tests for touch, rotation/camera and lifecycle

**Interfaces:**
- Produces normalized control events consumed by the native runtime.

- [ ] **Step 1: Write failing instrumentation tests for touch controls and lifecycle recreation.**
- [ ] **Step 2: Implement normalized input mapping and JNI transport.**
- [ ] **Step 3: Verify no input event reaches a destroyed native runtime.**
- [ ] **Step 4: Commit `feat: add Android flight controls`.**

### Task 7: Add audio and runtime services

**Files:**
- Create: `app/src/main/cpp/audio_bridge.cpp`
- Create: `native/runtime/service_manifest.lock`
- Modify: native CMake/runtime integration files as required by Tasks 3-5
- Test: native startup/audio smoke tests

**Interfaces:**
- Provides an Android-compatible audio path and runtime service manifest.

- [ ] **Step 1: Add failing service availability tests.**
- [ ] **Step 2: Implement the minimum native audio/runtime integration needed for FlightGear startup.**
- [ ] **Step 3: Verify startup with audio disabled and enabled.**
- [ ] **Step 4: Commit `feat: integrate Android runtime services`.**

### Task 8: Converge the CI pipeline

**Files:**
- Modify: `.github/workflows/android.yml`
- Create: `.github/workflows/convergence.yml`
- Create: `scripts/ci/verify-apk.sh`
- Create: `scripts/ci/verify-native.sh`

**Interfaces:**
- Consumes all previous tasks through their command-line build/test interfaces.
- Produces APK, native diagnostics, dependency/source manifests and test reports as artifacts.

- [ ] **Step 1: Add CI verification scripts and make them fail on missing artifacts.**
- [ ] **Step 2: Run them locally against the current incomplete build and record expected failures.**
- [ ] **Step 3: Implement a staged CI pipeline: bootstrap → native dependencies → FlightGear → runtime package → APK → static/ELF checks → smoke tests.**
- [ ] **Step 4: Preserve intermediate logs/artifacts on failure.**
- [ ] **Step 5: Run the complete workflow and require a successful APK artifact.**
- [ ] **Step 6: Commit `ci: add full convergence build`.**

### Task 9: Z Flip6 release validation and performance gate

**Files:**
- Create: `docs/validation/z-flip6.md`
- Create: `scripts/ci/performance-report.sh`
- Create: `scripts/ci/install-smoke.sh`
- Test: APK installation/startup and basic flight smoke scenario

**Interfaces:**
- Consumes the final APK/runtime artifact from Task 8.
- Produces a reproducible validation report covering installation, startup, rendering, controls and basic flight.

- [ ] **Step 1: Define measurable startup/render/input gates.**
- [ ] **Step 2: Run clean-install smoke validation.**
- [ ] **Step 3: Capture native/Android logs and performance counters.**
- [ ] **Step 4: Fix only blockers revealed by the gates.**
- [ ] **Step 5: Commit `test: validate Z Flip6 convergence build`.**

### Final convergence gate

- [ ] Run the full clean build from a fresh checkout.
- [ ] Verify all native ELF artifacts are `aarch64`.
- [ ] Verify APK contains the expected native libraries and runtime manifest.
- [ ] Install APK on the target Android environment.
- [ ] Launch FlightGear and acquire the Android render surface.
- [ ] Start the C172P scenario.
- [ ] Exercise touch/camera controls.
- [ ] Verify clean pause/resume and surface destruction/recreation.
- [ ] Capture CI and runtime evidence before declaring the build converged.
