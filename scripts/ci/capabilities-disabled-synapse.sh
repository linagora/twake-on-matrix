#!/usr/bin/env bash
# Second, disposable Synapse with profile edits disabled, for
# integration_test/tests/setting/settings_profile_capabilities_test.dart.
#
# Usage: capabilities-disabled-synapse.sh start <env-file>
#        capabilities-disabled-synapse.sh stop
#
# `start` registers one account and appends its CAPS_DISABLED_* defines to
# <env-file>. CAPS_SYNAPSE_APP_HOST is the host the app reaches the runner on
# (10.0.2.2 from the Android emulator).
set -euo pipefail

NAME="${CAPS_SYNAPSE_NAME:-synapse-capabilities-disabled}"
PORT="${CAPS_SYNAPSE_PORT:-8481}"
APP_HOST="${CAPS_SYNAPSE_APP_HOST:-10.0.2.2}"
CAPS_USER="${CAPS_SYNAPSE_USER:-dora}"
CAPS_PASSWORD="${CAPS_SYNAPSE_PASSWORD:-dorapassword}"
DATA="$(cd "$(dirname "$0")/../.." && pwd)/integration_test/synapse/data"

log() { echo "[capabilities-synapse] $*" >&2; }

start() {
  local env_file="$1"
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  docker run -d --name "$NAME" --tmpfs /data \
    --volume="$DATA/homeserver.yaml":/data/homeserver.yaml:rw \
    --volume="$DATA/localhost.log.config":/data/localhost.log.config:rw \
    --volume="$DATA/capabilities_disabled.yaml":/data/capabilities_disabled.yaml:ro \
    -p "$PORT:80" matrixdotorg/synapse:latest \
    run --config-path /data/homeserver.yaml \
    --config-path /data/capabilities_disabled.yaml >/dev/null

  local base="http://127.0.0.1:$PORT"
  local end=$((SECONDS + 60))
  until curl -sf --max-time 5 "$base/_matrix/client/versions" >/dev/null 2>&1; do
    if [ $SECONDS -ge $end ]; then
      log "Synapse did not become ready in 60s"
      docker logs "$NAME" >&2 || true
      exit 1
    fi
    sleep 1
  done

  curl -sS --fail-with-body --max-time 30 -X POST "$base/_matrix/client/v3/register" \
    -H "Content-Type: application/json" \
    -d "$(jq -nc --arg u "$CAPS_USER" --arg p "$CAPS_PASSWORD" \
      '{username: $u, password: $p, auth: {type: "m.login.dummy"}}')" \
    >/dev/null

  if [ -f "$env_file" ]; then
    local tmp rc=0
    tmp="$(mktemp)"
    # grep exits 1 when every line is a CAPS_DISABLED_ one; 2 is a real error.
    grep -v '^CAPS_DISABLED_' "$env_file" > "$tmp" || rc=$?
    if [ "$rc" -gt 1 ]; then
      rm -f "$tmp"
      log "could not filter $env_file"
      exit 1
    fi
    cat "$tmp" > "$env_file"
    rm -f "$tmp"
  fi
  {
    echo "CAPS_DISABLED_SERVER_URL=http://$APP_HOST:$PORT"
    echo "CAPS_DISABLED_USERNAME=$CAPS_USER"
    echo "CAPS_DISABLED_PASSWORD=$CAPS_PASSWORD"
  } >> "$env_file"
  log "ready on port $PORT"
}

case "${1:-}" in
  start) start "${2:?env file required}" ;;
  stop) docker rm -f "$NAME" >/dev/null 2>&1 || true ;;
  *) echo "usage: $0 start <env-file> | stop" >&2; exit 2 ;;
esac
