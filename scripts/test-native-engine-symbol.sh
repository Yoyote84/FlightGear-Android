#!/usr/bin/env bash
set -euo pipefail

LIBRARY="${1:?path to libflightgear_android.so required}"
SYMBOL="fg_android_surface_created"

if [[ ! -f "$LIBRARY" ]]; then
  echo "Missing native library: $LIBRARY" >&2
  exit 1
fi

if ! nm -D "$LIBRARY" | grep -q "[[:space:]]$SYMBOL$"; then
  echo "Native FlightGear engine symbol is not exported: $SYMBOL" >&2
  exit 1
fi

echo "Native FlightGear engine symbol verified: $SYMBOL"
