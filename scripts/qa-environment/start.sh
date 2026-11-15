#!/bin/bash
#
# Starts a long lived Synapse homeserver for manual or agent driven exploratory QA of the Android app,
# under its own compose project and port, kept up until stop.sh is called, and installs the debug APK
# of build.sh (image twake-chat-mobile-qa-apk) afresh on the emulator $ANDROID_SERIAL (already booted:
# this script never starts one), signed in as alice.
#
# Synapse is the one of the integration tests (integration_test/synapse/data), provisioned with the
# fixtures of the Patrol tests (scripts/integration-test-provision-synapse.sh): no SSO, the app goes
# to the password login. The emulator reaches it as http://10.0.2.2:$QA_MATRIX_PORT (the host), this
# host as http://localhost:$QA_MATRIX_PORT.
#
#   scripts/qa-environment/build.sh    # once, and whenever the code under test changes
#   ANDROID_SERIAL=emulator-5554 scripts/qa-environment/start.sh
#
# Accounts (server name localhost): alice / alicepassword (@alice:localhost), bob / bobpassword,
# charlie / charliepassword. alice owns the group TEST_GROUP (bob moderator, charlie member, three
# messages) and the rooms "Receiver Alpha" and "Receiver Beta" with bob.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
GENERATED_DIR="$SCRIPT_DIR/.generated"

QA_PROJECT="${QA_PROJECT:-twake-chat-mobile-qa}"
export QA_MATRIX_PORT="${QA_MATRIX_PORT:-18971}"
PACKAGE=app.twake.android.chat
APK="$GENERATED_DIR/twake-chat-qa.apk"
MATRIX_URL="http://localhost:$QA_MATRIX_PORT"
# 10.0.2.2: the host, as the Android emulator sees it
DEVICE_MATRIX_URL="http://10.0.2.2:$QA_MATRIX_PORT"

export ANDROID_SERIAL="${ANDROID_SERIAL:?the emulator under test, e.g. emulator-5554}"
export PATH="${ANDROID_HOME:-$HOME/Android/Sdk}/platform-tools:$HOME/.maestro/bin:$PATH"
export MAESTRO_CLI_NO_ANALYTICS="${MAESTRO_CLI_NO_ANALYTICS:-1}"

compose() {
  docker compose -p "$QA_PROJECT" -f "$SCRIPT_DIR/docker-compose.yaml" "$@"
}

command -v jq >/dev/null || { echo "jq is required (provisioning)" >&2; exit 1; }
command -v adb >/dev/null || { echo "adb is not on the PATH (Android SDK platform-tools)" >&2; exit 1; }
command -v maestro >/dev/null || { echo "maestro is not on the PATH (https://docs.maestro.dev)" >&2; exit 1; }
docker image inspect twake-chat-mobile-qa-apk >/dev/null 2>&1 ||
  { echo "The twake-chat-mobile-qa-apk image is missing, build it first: scripts/qa-environment/build.sh" >&2; exit 1; }
[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] ||
  { echo "$ANDROID_SERIAL is not a booted device" >&2; exit 1; }

mkdir -p "$GENERATED_DIR"

echo "==> Starting Synapse as compose project '$QA_PROJECT'"
# A fresh homeserver every time: the provisioning registers fixed accounts
compose down --volumes --remove-orphans >/dev/null 2>&1 || true
compose up -d

echo "==> Provisioning Synapse"
SYNAPSE_URL="$MATRIX_URL" READY_TIMEOUT=180 \
  "$REPO_DIR/scripts/integration-test-provision-synapse.sh" > "$GENERATED_DIR/provisioning.env"

echo "==> Installing the APK of twake-chat-mobile-qa-apk on $ANDROID_SERIAL"
container="$(docker create twake-chat-mobile-qa-apk none)"
docker cp -q "$container:/twake-chat-qa.apk" "$APK"
docker rm "$container" >/dev/null
# Uninstalling drops the session and the cache of the previous run
adb uninstall "$PACKAGE" >/dev/null 2>&1 || true
adb install "$APK"
for permission in POST_NOTIFICATIONS READ_CONTACTS; do
  adb shell pm grant "$PACKAGE" "android.permission.$permission" 2>/dev/null ||
    echo "    android.permission.$permission not granted (not requested by the app on this Android?)"
done

echo "==> Signing in as alice"
maestro --device "$ANDROID_SERIAL" test -e SERVER="$DEVICE_MATRIX_URL" -e USERNAME=alice \
  -e PASSWORD=alicepassword "$SCRIPT_DIR/sign-in.yaml"
adb shell am force-stop dev.mobile.maestro.test 2>/dev/null || true

cat <<INFO

==> The QA environment is up

  Twake Chat ($PACKAGE, debug build) on $ANDROID_SERIAL, signed in as alice / alicepassword
  Homeserver in the app: $DEVICE_MATRIX_URL  (server name localhost, password login, no SSO)
  From this host:        $MATRIX_URL/_matrix/client/v3/
  Accounts:              alice / alicepassword, bob / bobpassword, charlie / charliepassword
  Fixtures:              $GENERATED_DIR/provisioning.env

Stop it with: ANDROID_SERIAL=$ANDROID_SERIAL scripts/qa-environment/stop.sh
INFO
