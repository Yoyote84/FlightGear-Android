# Android native patches

This directory contains only patches required to make the pinned FlightGear/SimGear/OpenSceneGraph sources build correctly for Android ARM64.

The baseline is intentionally empty: `native/bootstrap/apply_patches.sh` is a no-op when no `*.patch` files are present. A patch must be added only with a documented reason, upstream issue/commit reference, and a deterministic test that demonstrates the pre-patch failure and post-patch fix.

Do not copy or fork the upstream source tree into this directory.
