#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK="${1:-$ROOT/app/build/outputs/apk/debug/app-debug.apk}"
SERIAL="${2:-${REA_ANDROID_SERIAL:-}}"

if [[ ! -f "$APK" ]]; then
  echo "APK introuvable: $APK" >&2
  echo "Construis d'abord : gradle --no-daemon :app:assembleDebug" >&2
  exit 1
fi

if command -v rea >/dev/null 2>&1; then
  REA=(rea)
elif command -v npx >/dev/null 2>&1; then
  REA=(npx -y rea-agents@latest)
else
  echo "REA introuvable. Installe Node.js puis rea-agents, ou utilise npx." >&2
  exit 1
fi

echo "=== REA : analyse statique de l'APK ==="
"${REA[@]}" inspect-android-package "$APK"

if [[ -n "$SERIAL" ]]; then
  echo
  echo "=== REA : client ADB ==="
  "${REA[@]}" inspect-adb-client
  echo
  echo "=== REA : appareil $SERIAL ==="
  "${REA[@]}" inspect-adb-device "$SERIAL"
  echo
  echo "=== REA : processus FlightGear/Android ==="
  "${REA[@]}" list-adb-processes "$SERIAL"
  echo
  echo "=== REA : logcat récent ==="
  "${REA[@]}" read-adb-logcat "$SERIAL" --count 400
fi
