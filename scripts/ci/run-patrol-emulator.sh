#!/usr/bin/env bash
# Runs one Patrol test target against an already-booted Android emulator.
#
# Invoked as a single line from the `reactivecircus/android-emulator-runner`
# `script` input: that action executes the script line by line, so anything
# relying on multi-line shell (backslash continuations, variables) must live
# in a file like this one.
#
# Usage: run-patrol-emulator.sh <patrol-test-target> [device-id]
set -euo pipefail

TARGET="${1:?usage: run-patrol-emulator.sh <patrol-test-target> [device-id]}"
DEVICE="${2:-emulator-5554}"

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

echo "=== patrol version ==="
patrol --version || true

echo "=== patrol test: $TARGET ==="
patrol test \
  -d "$DEVICE" \
  --target "$TARGET" \
  --dart-define-from-file .env.cicd \
  -v
