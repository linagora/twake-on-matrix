#!/bin/bash
#
# Stops the QA environment started by start.sh. Synapse keeps its data in a tmpfs: it is gone once
# stopped. Also leaves the emulator $ANDROID_SERIAL as a run found it: the app uninstalled, airplane
# mode off, Maestro's driver stopped; only when the QA stack was running: otherwise another run may be
# using the emulator.
#
#   ANDROID_SERIAL=emulator-5554 scripts/qa-environment/stop.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

QA_PROJECT="${QA_PROJECT:-twake-chat-mobile-qa}"

# compose interpolates the whole file even to stop it
export QA_MATRIX_PORT=0
RUNNING="$(docker compose -p "$QA_PROJECT" ps -q 2>/dev/null || true)"
docker compose -p "$QA_PROJECT" -f "$SCRIPT_DIR/docker-compose.yaml" down --volumes --remove-orphans
if [ -n "$RUNNING" ] && [ -n "${ANDROID_SERIAL:-}" ]; then
  export PATH="${ANDROID_HOME:-$HOME/Android/Sdk}/platform-tools:$PATH"
  if adb get-state >/dev/null 2>&1; then
    adb uninstall app.twake.android.chat >/dev/null || true
    adb shell cmd connectivity airplane-mode disable || true
    adb shell am force-stop dev.mobile.maestro.test || true
    adb shell am force-stop dev.mobile.maestro || true
  fi
fi
echo "==> QA environment '$QA_PROJECT' stopped"
