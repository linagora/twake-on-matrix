#!/usr/bin/env bash
# Provision the FTL/staging test account with the rooms required by
# integration_test/tests/chat/perf_test.dart:
#
#   NavRoom     — used for navigation cycles (list → room → back)
#   ScrollRoom1 — image-heavy room for the 30s scroll scenario
#   ScrollRoom2 — second image-heavy room
#
# Idempotent: existing rooms (matched by name) are reused, only missing
# messages/images are topped up.
#
# Usage: ./scripts/provision-perf-rooms.sh [env-file]
#   env-file defaults to integration_test/.env.local.do-not-commit

set -euo pipefail

ENV_FILE="${1:-integration_test/.env.local.do-not-commit}"

NAV_ROOM_NAME="${NAV_ROOM_NAME:-PerfNav}"
SCROLL_ROOM_1_NAME="${SCROLL_ROOM_1_NAME:-PerfScrollA}"
SCROLL_ROOM_2_NAME="${SCROLL_ROOM_2_NAME:-PerfScrollB}"
TEXT_MSG_COUNT="${TEXT_MSG_COUNT:-120}"
IMAGE_COUNT="${IMAGE_COUNT:-25}"

get() { grep -E "^$1=" "$ENV_FILE" | cut -d= -f2-; }

SERVER="$(get SERVER_URL)"
USER_NAME="$(get USERNAME)"
PASSWORD="$(get PASSWORD)"

[ -n "$SERVER" ] && [ -n "$USER_NAME" ] && [ -n "$PASSWORD" ] \
  || { echo "ERROR: SERVER_URL/USERNAME/PASSWORD missing in $ENV_FILE"; exit 1; }

log() { echo "[perf-provision] $*" >&2; }

api() { # api METHOD PATH [DATA] — retries on 429/5xx with backoff
  local method="$1" path="$2" data="${3:-}"
  local attempt=1 max=6 wait=5
  while true; do
    local out code
    if [ -n "$data" ]; then
      out=$(curl -sS -X "$method" "$SERVER$path" \
        -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
        -d "$data" -w $'\n%{http_code}') || true
    else
      out=$(curl -sS -X "$method" "$SERVER$path" \
        -H "Authorization: Bearer $TOKEN" -w $'\n%{http_code}') || true
    fi
    code=$(printf '%s' "$out" | tail -n1)
    out=$(printf '%s' "$out" | sed '$d')
    if [ "$code" -lt 400 ] 2>/dev/null; then
      printf '%s' "$out"
      return 0
    fi
    if { [ "$code" = "429" ] || [ "$code" -ge 500 ] 2>/dev/null; } && [ $attempt -lt $max ]; then
      log "HTTP $code on $method $path — retry $attempt/$max in ${wait}s"
      sleep "$wait"
      wait=$((wait * 2))
      attempt=$((attempt + 1))
      continue
    fi
    log "ERROR: $method $path → HTTP $code: $out"
    return 1
  done
}

log "Logging in as $USER_NAME on $SERVER..."
TOKEN=""
for attempt in 1 2 3 4 5; do
  RESP=$(curl -sS -X POST "$SERVER/_matrix/client/v3/login" \
    -H "Content-Type: application/json" \
    -d "$(jq -nc --arg u "$USER_NAME" --arg p "$PASSWORD" \
          '{type:"m.login.password", identifier:{type:"m.id.user", user:$u}, password:$p}')" \
    || true)
  TOKEN=$(printf '%s' "$RESP" | jq -r '.access_token // empty')
  if [ -n "$TOKEN" ]; then break; fi
  log "Login attempt $attempt failed ($(printf '%s' "$RESP" | jq -r '.errcode // "?"')) — waiting..."
  sleep $((attempt * 15))
done
[ -n "$TOKEN" ] || { echo "ERROR: login failed"; exit 1; }

# Map existing room names → ids (idempotency). bash 3.2 compatible: flat
# "name<TAB>id" lines in a temp file instead of an associative array.
EXISTING_FILE=$(mktemp)
trap 'rm -f "$EXISTING_FILE"' EXIT

api GET "/_matrix/client/v3/joined_rooms" | jq -r '.joined_rooms[]' | while read -r rid; do
  n=$(api GET "/_matrix/client/v3/rooms/$rid/state/m.room.name" 2>/dev/null | jq -r '.name // empty' || true)
  if [ -n "$n" ]; then
    printf '%s\t%s\n' "$n" "$rid" >> "$EXISTING_FILE"
  fi
done

find_room_by_name() { # find_room_by_name NAME → room_id or empty
  awk -F '\t' -v n="$1" '$1 == n {print $2; exit}' "$EXISTING_FILE"
}

ensure_room() { # ensure_room NAME → room_id
  local name="$1" rid
  rid=$(find_room_by_name "$name")
  if [ -n "$rid" ]; then
    log "Room '$name' already exists: $rid"
    echo "$rid"
    return
  fi
  rid=$(api POST "/_matrix/client/v3/createRoom" \
    "$(jq -nc --arg n "$name" '{name:$n, preset:"private_chat", visibility:"private"}')" \
    | jq -r '.room_id')
  [ -n "$rid" ] && [ "$rid" != "null" ] || { echo "ERROR: createRoom '$name' failed"; exit 1; }
  log "Created room '$name': $rid"
  echo "$rid"
}

send_text() { # send_text ROOM_ID BODY
  api PUT "/_matrix/client/v3/rooms/$1/send/m.room.message/perf-$RANDOM-$(date +%s%N)" \
    "$(jq -nc --arg b "$2" '{msgtype:"m.text", body:$b}')" >/dev/null
}

make_png() { # make_png PATH SEED — small unique PNG (renders fast, distinct in cache)
  python3 - "$1" "$2" <<'PY'
import random, struct, sys, zlib
path, seed = sys.argv[1], int(sys.argv[2])
rng = random.Random(seed)
w = h = 96
raw = b""
for _ in range(h):
    raw += b"\x00" + b"".join(rng.randbytes(3) for _ in range(w))
def chunk(t, d):
    c = t + d
    return struct.pack(">I", len(d)) + c + struct.pack(">I", zlib.crc32(c))
ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)
png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr)
       + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))
open(path, "wb").write(png)
PY
}

send_image() { # send_image ROOM_ID PNG_PATH
  local room="$1" png="$2"
  local mxc
  mxc=$(curl -sS --fail-with-body -X POST \
    "$SERVER/_matrix/media/v3/upload?filename=perf-$(basename "$png")" \
    -H "Authorization: Bearer $TOKEN" -H "Content-Type: image/png" \
    --data-binary "@$png" | jq -r '.content_uri')
  api PUT "/_matrix/client/v3/rooms/$room/send/m.room.message/perf-$RANDOM-$(date +%s%N)" \
    "$(jq -nc --arg u "$mxc" '{msgtype:"m.image", body:"perf.png", url:$u,
       info:{mimetype:"image/png", w:96, h:96}}')" >/dev/null
}

seed_room() { # seed_room ROOM_ID LABEL
  local room="$1" label="$2" tmpdir
  tmpdir=$(mktemp -d)
  log "Seeding $label ($room): $TEXT_MSG_COUNT text + $IMAGE_COUNT images..."
  for i in $(seq 1 "$TEXT_MSG_COUNT"); do
    send_text "$room" "[$label] seed message $i/$TEXT_MSG_COUNT — perf scroll fixture, do not delete."
    if [ $((i % 5)) -eq 0 ] && [ $((i / 5)) -le "$IMAGE_COUNT" ]; then
      make_png "$tmpdir/img$i.png" "$i"
      send_image "$room" "$tmpdir/img$i.png"
    fi
    # Stay under Synapse rate limits on staging (~290 calls total per room).
    sleep 0.2
  done
  rm -rf "$tmpdir"
}

NAV_ID=$(ensure_room "$NAV_ROOM_NAME")
SCROLL1_ID=$(ensure_room "$SCROLL_ROOM_1_NAME")
SCROLL2_ID=$(ensure_room "$SCROLL_ROOM_2_NAME")

# Nav room only needs to exist and open quickly — a few messages are enough.
send_text "$NAV_ID" "nav fixture message" || true

seed_room "$SCROLL1_ID" "$SCROLL_ROOM_1_NAME"
seed_room "$SCROLL2_ID" "$SCROLL_ROOM_2_NAME"

log "Done. Add these to INTEGRATION_TEST_ENV_BASE64:"
cat <<EOF
NavRoom=$NAV_ROOM_NAME
ScrollRoom1=$SCROLL_ROOM_1_NAME
ScrollRoom2=$SCROLL_ROOM_2_NAME
EOF
