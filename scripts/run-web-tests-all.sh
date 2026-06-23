#!/usr/bin/env bash
set -uo pipefail

cd "$(dirname "$0")/.."

# Source values from the provisioning script output
if [ ! -f .env.patrol-web ]; then
  echo "Missing .env.patrol-web — run: scripts/integration-test-provision-synapse.sh > .env.patrol-web" >&2
  exit 1
fi
# shellcheck disable=SC1091
set -a
. ./.env.patrol-web
set +a

run_test() {
  local test="$1"
  local name
  name=$(basename "$test" .dart)

  echo ""
  echo "━━━ Running: $name ━━━"

  local output
  output=$(patrol test \
    --target "$test" \
    --device chrome \
    --web-headless=true \
    --web-timeout 600000 \
    --web-server-timeout 600 \
    --dart-define=MATRIX_URL="$MATRIX_URL" \
    --dart-define=SERVER_URL="$SERVER_URL" \
    --dart-define=USERNAME="$USERNAME" \
    --dart-define=PASSWORD="$PASSWORD" \
    --dart-define=Receiver="$Receiver" \
    --dart-define=ReceiverPass="$ReceiverPass" \
    --dart-define=CurrentAccount="$CurrentAccount" \
    --dart-define=MemberMatrixID="$MemberMatrixID" \
    --dart-define=SearchByMatrixAddress="$SearchByMatrixAddress" \
    --dart-define=SearchByTitle="$SearchByTitle" \
    --dart-define=TitleOfGroupTest="$TitleOfGroupTest" \
    --dart-define=GroupID="$GroupID" \
    --dart-define=PATROL_WEB=true 2>&1)
  local ec=$?

  if [ $ec -eq 0 ]; then
    echo "✅ PASSED: $name"
    echo "✅ $name" >> /tmp/patrol-web-results.txt
  else
    local reason
    reason=$(echo "$output" | grep -E "TimeoutException|MatrixException|TestFailure|Playwright process exited|EXCEPTION" | head -1 | sed 's/\x1b\[[0-9;]*m//g' | cut -c1-100)
    echo "❌ FAILED: $name — $reason"
    echo "❌ $name — $reason" >> /tmp/patrol-web-results.txt
  fi
}

: > /tmp/patrol-web-results.txt

TESTS=(
  integration_test/tests/login/login_with_password_test.dart
  integration_test/tests/setting/language_test.dart
  integration_test/tests/setting/settings_contacts_visibility_test.dart
  integration_test/tests/setting/settings_recovery_key_test.dart
  integration_test/tests/contact/contact_test.dart
  integration_test/tests/chat/chat_list_test.dart
  integration_test/tests/chat/chat_test.dart
  integration_test/tests/chat/chat_dm_leave_test.dart
  integration_test/tests/chat/chat_group_test.dart
  integration_test/tests/chat/chat_group_open_profile_test.dart
  integration_test/tests/chat/sending_message_test.dart
  integration_test/tests/chat/forward_message_test.dart
  integration_test/tests/chat/create_direct_chat_with_unsupported_matrix_user_test.dart
  integration_test/tests/chat/create_new_group_chat_test.dart
  integration_test/tests/chat/search_external_mxid_test.dart
  integration_test/tests/chat/message_context_menu_safe_area_patrol_test.dart
  integration_test/tests/chat/transfer_ownership_test.dart
)

for test in "${TESTS[@]}"; do
  run_test "$test"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "FINAL RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat /tmp/patrol-web-results.txt
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
