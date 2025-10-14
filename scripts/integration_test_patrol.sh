#!/usr/bin/env sh
set -e

# --- Config --------------------------------------------------------------
UDID="DDDF0F2B-507B-43EE-AE0B-CABF4ED25D1F"   # Simulator UDID của bạn
# Nếu không truyền tham số, sẽ dùng danh sách mặc định dưới đây:
DEFAULT_FILES="
integration_test/data/PndFile1.png
integration_test/data/PdfFile1.pdf
integration_test/data/MovVideo1.mov
"
# ------------------------------------------------------------------------

# Lấy danh sách file cần seed: ưu tiên tham số dòng lệnh
if [ "$#" -gt 0 ]; then
  FILES="$*"
else
  FILES="$DEFAULT_FILES"
fi

# Validate từng file
MISSING=0
for SRC in $FILES; do
  if [ ! -f "$SRC" ]; then
    echo "❌ Source not found: $SRC"
    MISSING=1
  fi
done
[ "$MISSING" -eq 0 ] || exit 1

DEVICE_ROOT="$HOME/Library/Developer/CoreSimulator/Devices/$UDID/data"
echo "➡️  Seeding files into 'On My iPhone → Downloads' on device $UDID"
echo "   Files:"
for SRC in $FILES; do echo "     • $SRC"; done

# Tìm mọi thư mục "File Provider Storage"
TMP_LIST="$(mktemp)"
find "$DEVICE_ROOT" -type d -name "File Provider Storage" -maxdepth 7 -print 2>/dev/null > "$TMP_LIST"

if [ ! -s "$TMP_LIST" ]; then
  echo "❌ Not found: 'File Provider Storage'."
  echo "   Open the Files app on the simulator (browse 'On My iPhone' once), then re-run."
  rm -f "$TMP_LIST"
  exit 1
fi

# Copy tất cả file vào mỗi "…/File Provider Storage/Downloads"
while IFS= read -r P; do
  DEST="$P/Downloads"
  echo "→ Seeding to: $DEST"
  if mkdir -p "$DEST" 2>/dev/null; then
    OK_ANY=0
    for SRC in $FILES; do
      if /bin/cp -f "$SRC" "$DEST/"; then
        OK_ANY=1
        echo "   ✅ Copied: $(basename "$SRC")"
      else
        echo "   ❌ Copy failed: $SRC"
      fi
    done
    if [ "$OK_ANY" -eq 1 ]; then
      echo "   📄 Contents now:"
      /bin/ls -l "$DEST/" | sed 's/^/      /'
    fi
  else
    echo "   ❌ mkdir failed (possibly read-only): $DEST"
  fi
done < "$TMP_LIST"

rm -f "$TMP_LIST"


ENV_FILE=integration_test/.env.local.do-not-commit
patrol test \
  --dart-define-from-file="$ENV_FILE" \
  --device "$(grep -E '^DEVICE=' "$ENV_FILE" | cut -d= -f2-)"