#!/usr/bin/env bash
# Run a single Patrol web test (Chrome headless) against the local Synapse.
# Usage: scripts/run-one-web.sh integration_test/tests/chat/<file>.dart
set -uo pipefail

cd "$(dirname "$0")/.."

# Use the working pinned SDK directly (the fvm/global shim throws
# "Invalid SDK hash" on this machine).
export PATH="$HOME/fvm/versions/3.38.9/bin:$PATH"

if [ ! -f .env.patrol-web ]; then
  echo "Missing .env.patrol-web — run: scripts/integration-test-provision-synapse.sh > .env.patrol-web" >&2
  exit 1
fi
# shellcheck disable=SC1091
set -a
. ./.env.patrol-web
set +a

TEST="${1:?usage: run-one-web.sh <test.dart>}"

patrol test \
  --target "$TEST" \
  --device chrome \
  --web-headless=true \
  --web-timeout 600000 \
  --web-server-timeout 600 \
  --dart-define=MATRIX_URL="$MATRIX_URL" \
  --dart-define=SERVER_URL="$SERVER_URL" \
  --dart-define=USERNAME="$TEST_USERNAME" \
  --dart-define=PASSWORD="$TEST_PASSWORD" \
  --dart-define=Receiver="$Receiver" \
  --dart-define=ReceiverPass="$ReceiverPass" \
  --dart-define=CurrentAccount="$CurrentAccount" \
  --dart-define=MemberMatrixID="$MemberMatrixID" \
  --dart-define=SearchByMatrixAddress="$SearchByMatrixAddress" \
  --dart-define=SearchByTitle="$SearchByTitle" \
  --dart-define=TitleOfGroupTest="$TitleOfGroupTest" \
  --dart-define=GroupTest="$SearchByTitle" \
  --dart-define=GroupID="$GroupID" \
  --dart-define=PATROL_WEB=true 2>&1 | tee /tmp/patrol-last.log

# Patrol web exits 0 even when tests fail — derive the real status from the
# summary line instead of $?.
if grep -qE '^❌ Failed: 0$' /tmp/patrol-last.log && grep -qE '^✅ Successful: [1-9]' /tmp/patrol-last.log; then
  echo "RESULT=GREEN"
  exit 0
else
  echo "RESULT=RED"
  exit 1
fi
