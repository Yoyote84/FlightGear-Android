# Native source bootstrap

This directory owns the reproducible source bootstrap for the Android ARM64 build.

## Pinned baseline

The first convergence baseline uses the stable FlightGear 2024.1.1 release family:

- FlightGear `v2024.1.1`
- SimGear `v2024.1.1`
- OpenSceneGraph `OpenSceneGraph-3.6.5`

FlightGear documents 2024.1.1 as the supported stable release and notes that the 2024.1 series is the last release before the newer rendering pipeline work. The release build is known to pair FlightGear/SimGear 2024.1.1 with OpenSceneGraph 3.6.5.

The manifest records both the Git revision and a checksum field derived from that immutable Git object ID. Later bootstrap stages must consume this manifest rather than floating branches.

## Verification

Run from the repository root:

```bash
bash native/bootstrap/verify_manifest.sh
```

A successful run prints `PASS: native dependency manifest is structurally complete`.

## Source layout contract

Later bootstrap stages will materialize the pinned sources below `native/src/` and record the exact revisions in `native/build/source-stamp.txt`.
