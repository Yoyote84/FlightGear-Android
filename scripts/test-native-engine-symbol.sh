#!/usr/bin/env bash
set -euo pipefail

LIBRARY="${1:?path to libflightgear_android.so required}"
SYMBOL="fgInitConfig"

if [[ ! -f "$LIBRARY" ]]; then
  echo "Missing native library: $LIBRARY" >&2
  exit 1
fi

if ! nm -D "$LIBRARY" | grep -q "[[:space:]]$SYMBOL"; then
  echo "FlightGear Main engine symbol is not linked into libflightgear_android.so: $SYMBOL" >&2
  exit 1
fi

echo "FlightGear Main engine symbol verified: $SYMBOL"
