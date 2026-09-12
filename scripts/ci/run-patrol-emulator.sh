#!/usr/bin/env bash
# Runs one or more Patrol test targets against an already-booted Android
# emulator.
#
# Invoked as a single line from the `reactivecircus/android-emulator-runner`
# `script` input: that action executes the script line by line, so anything
# relying on multi-line shell (backslash continuations, variables) must live
# in a file like this one.
#
# Usage: run-patrol-emulator.sh <target> [<target> ...]
#        (device id defaults to emulator-5554)
set -euo pipefail

if [[ "$#" -lt 1 ]]; then
  echo "::error::usage: run-patrol-emulator.sh <target> [<target> ...]" >&2
  exit 2
fi

DEVICE="${PATROL_DEVICE:-emulator-5554}"
ADB="${ANDROID_SDK_ROOT:-/usr/local/lib/android/sdk}/platform-tools/adb"

export PATH="$PATH:$HOME/.pub-cache/bin"

if [[ ! -f .env.cicd ]]; then
  echo "::error::.env.cicd is missing (INTEGRATION_TEST_ENV_BASE64 was not decoded)"
  exit 1
fi

echo "=== env file diagnostics (keys + value lengths) ==="
while IFS='=' read -r key value; do
  [[ -z "$key" || "$key" == \#* ]] && continue
  printf '%s=%s chars\n' "$key" "${#value}"
done < .env.cicd

target_args=()
for target in "$@"; do
  target_args+=(--target "$target")
done

echo "=== patrol test on $DEVICE ==="
printf '  target: %s\n' "$@"

# Capture logcat so a native crash ("Process crashed") can be diagnosed: the
# Gradle output alone does not say why the app process died.
"$ADB" -s "$DEVICE" logcat -c || true
"$ADB" -s "$DEVICE" logcat > logcat.txt 2>&1 &
logcat_pid=$!

set +e
patrol test \
  -d "$DEVICE" \
  "${target_args[@]}" \
  --dart-define-from-file .env.cicd \
  -v
status=$?
set -e

kill "$logcat_pid" 2>/dev/null || true
wait "$logcat_pid" 2>/dev/null || true

echo "=== crash signatures from logcat ==="
grep -aE -A30 "FATAL EXCEPTION|Fatal signal|SIGSEGV|SIGABRT|Process crashed|tombstone|Abort message" logcat.txt \
  | tail -n 200 || true

exit "$status"
