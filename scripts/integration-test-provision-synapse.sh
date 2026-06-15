#!/usr/bin/env bash
# Provision a freshly started Synapse homeserver with the fixtures required
# by the Patrol integration tests: users, a shared group, some power-level
# tweaks, and a handful of seed messages.
#
# The container started by `scripts/integration-server-synapse.sh` uses
# `--tmpfs /data`, so every run starts empty. Registration is public and
# unverified (see `integration_test/synapse/data/homeserver.yaml`), so we
# can create accounts straight through the public client-server API.
#
# Outputs an env-file on stdout that the patrol run can source to pick up
# the matching `--dart-define`s.

set -euo pipefail

BASE_URL="${SYNAPSE_URL:-http://localhost}"
SERVER_NAME="${SYNAPSE_SERVER_NAME:-localhost}"
USER1="${USER1:-alice}"
PASSWORD1="${PASSWORD1:-alicepassword}"
USER2="${USER2:-bob}"
PASSWORD2="${PASSWORD2:-bobpassword}"
USER3="${USER3:-charlie}"
PASSWORD3="${PASSWORD3:-charliepassword}"
ROOM_NAME="${ROOM_NAME:-TEST_GROUP}"
READY_TIMEOUT="${READY_TIMEOUT:-60}"

log() { echo "[provision] $*" >&2; }

wait_for_synapse() {
  log "Waiting for Synapse at $BASE_URL (up to ${READY_TIMEOUT}s)..."
  local end=$((SECONDS + READY_TIMEOUT))
  while [ $SECONDS -lt $end ]; do
    if curl -sf "$BASE_URL/_matrix/client/versions" >/dev/null 2>&1; then
      log "Synapse is up."
      return
    fi
    sleep 1
  done
  log "Synapse did not become ready in ${READY_TIMEOUT}s"
  exit 1
}

register_user() {
  local user="$1"
  local pass="$2"
  local payload
  payload=$(jq -nc \
    --arg user "$user" \
    --arg pass "$pass" \
    '{
      username: $user,
      password: $pass,
      auth: {type: "m.login.dummy"},
      initial_device_display_name: "integration-test-setup"
    }')
  local response
  response=$(curl -sS --fail-with-body -X POST \
    "$BASE_URL/_matrix/client/v3/register" \
    -H "Content-Type: application/json" \
    -d "$payload")
  local token
  token=$(echo "$response" | jq -r '.access_token // empty')
  if [ -z "$token" ]; then
    log "Failed to register $user: $response"
    exit 1
  fi
  echo "$token"
}

create_room() {
  local owner_token="$1"
  local mxid1="$2"
  local mxid2="$3"
  local mxid3="$4"
  local payload
  payload=$(jq -nc \
    --arg name "$ROOM_NAME" \
    --arg mxid1 "$mxid1" \
    --arg mxid2 "$mxid2" \
    --arg mxid3 "$mxid3" \
    '{
      name: $name,
      preset: "private_chat",
      visibility: "private",
      invite: [$mxid2, $mxid3],
      power_level_content_override: {
        users: {($mxid1): 100, ($mxid2): 50}
      }
    }')
  local response
  response=$(curl -sS --fail-with-body -X POST \
    "$BASE_URL/_matrix/client/v3/createRoom" \
    -H "Authorization: Bearer $owner_token" \
    -H "Content-Type: application/json" \
    -d "$payload")
  local room_id
  room_id=$(echo "$response" | jq -r '.room_id // empty')
  if [ -z "$room_id" ]; then
    log "createRoom failed: $response"
    exit 1
  fi
  echo "$room_id"
}

create_named_room() {
  local owner_token="$1"
  local name="$2"
  local invitee="$3"
  local payload
  payload=$(jq -nc \
    --arg name "$name" \
    --arg invitee "$invitee" \
    '{
      name: $name,
      preset: "private_chat",
      visibility: "private",
      invite: [$invitee]
    }')
  local response
  response=$(curl -sS --fail-with-body -X POST \
    "$BASE_URL/_matrix/client/v3/createRoom" \
    -H "Authorization: Bearer $owner_token" \
    -H "Content-Type: application/json" \
    -d "$payload")
  local room_id
  room_id=$(echo "$response" | jq -r '.room_id // empty')
  if [ -z "$room_id" ]; then
    log "create_named_room '$name' failed: $response"
    exit 1
  fi
  echo "$room_id"
}

accept_invite() {
  local token="$1"
  local room_id="$2"
  curl -sS --fail-with-body -X POST \
    "$BASE_URL/_matrix/client/v3/rooms/$room_id/join" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d '{}' >/dev/null
}

send_message() {
  local token="$1"
  local room_id="$2"
  local body="$3"
  local txn_id="txn-$RANDOM-$(date +%s%N)"
  local payload
  payload=$(jq -nc --arg body "$body" '{msgtype: "m.text", body: $body}')
  curl -sS --fail-with-body -X PUT \
    "$BASE_URL/_matrix/client/v3/rooms/$room_id/send/m.room.message/$txn_id" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d "$payload" >/dev/null
}

wait_for_synapse

log "Registering $USER1, $USER2, $USER3..."
TOKEN1=$(register_user "$USER1" "$PASSWORD1")
TOKEN2=$(register_user "$USER2" "$PASSWORD2")
TOKEN3=$(register_user "$USER3" "$PASSWORD3")

MXID1="@$USER1:$SERVER_NAME"
MXID2="@$USER2:$SERVER_NAME"
MXID3="@$USER3:$SERVER_NAME"

log "Creating $ROOM_NAME with $USER1 as admin..."
ROOM_ID=$(create_room "$TOKEN1" "$MXID1" "$MXID2" "$MXID3")

log "Joining invitees to $ROOM_ID..."
accept_invite "$TOKEN2" "$ROOM_ID"
accept_invite "$TOKEN3" "$ROOM_ID"

log "Seeding test messages..."
send_message "$TOKEN1" "$ROOM_ID" "Hello from $USER1"
send_message "$TOKEN2" "$ROOM_ID" "Reply from $USER2"
send_message "$TOKEN1" "$ROOM_ID" "Follow-up from $USER1"

# Forward-test receiver rooms — distinct destinations $USER1 can forward to.
# Non-overlapping names: a textContaining finder on "Receiver Group" would also
# match "Receiver Group 2", so use names where neither is a prefix of the other.
RECEIVER1_NAME="${RECEIVER1_NAME:-Receiver Alpha}"
RECEIVER2_NAME="${RECEIVER2_NAME:-Receiver Beta}"
log "Creating forward receiver rooms '$RECEIVER1_NAME' and '$RECEIVER2_NAME'..."
RECEIVER1_ID=$(create_named_room "$TOKEN1" "$RECEIVER1_NAME" "$MXID2")
RECEIVER2_ID=$(create_named_room "$TOKEN1" "$RECEIVER2_NAME" "$MXID2")
accept_invite "$TOKEN2" "$RECEIVER1_ID"
accept_invite "$TOKEN2" "$RECEIVER2_ID"

log "Provisioning complete."

# TEST_USERNAME / TEST_PASSWORD instead of USERNAME / PASSWORD because zsh
# (macOS default) treats USERNAME as a read-only built-in — assignments are
# silently ignored, causing local patrol runs to send the OS login name.
cat <<EOF
MATRIX_URL=$BASE_URL
SERVER_URL=$BASE_URL
TEST_USERNAME=$USER1
TEST_PASSWORD=$PASSWORD1
Receiver=$USER2
ReceiverPass=$PASSWORD2
CurrentAccount=$MXID1
MemberMatrixID=$MXID2
SearchByMatrixAddress=$MXID3
SearchByTitle=$ROOM_NAME
TitleOfGroupTest=$ROOM_NAME
GroupID=$ROOM_ID
ForwardReceiver1Name="$RECEIVER1_NAME"
ForwardReceiver2Name="$RECEIVER2_NAME"
EOF
