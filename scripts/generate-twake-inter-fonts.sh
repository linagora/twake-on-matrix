#!/usr/bin/env bash
# generate-twake-inter-fonts.sh
#
# Downloads the latest Inter font release, strips emoji glyphs that interfere
# with color emoji rendering on Flutter web, and renames font metadata from
# "Inter" to "TwakeInter". Output is placed in assets/google_fonts/.
#
# Requirements:
#   - python3 with fonttools  (pip3 install fonttools)
#   - curl, unzip
#
# Usage:
#   bash scripts/generate-twake-inter-fonts.sh [--inter-version 4.1]

set -euo pipefail

INTER_VERSION="${INTER_VERSION:-4.1}"
OUT_DIR="assets/google_fonts"
TMP_DIR="$(mktemp -d)"

# Parse optional --inter-version flag
while [[ $# -gt 0 ]]; do
  case "$1" in
    --inter-version) INTER_VERSION="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

DOWNLOAD_URL="https://github.com/rsms/inter/releases/download/v${INTER_VERSION}/Inter-${INTER_VERSION}.zip"
ZIP_PATH="${TMP_DIR}/Inter-${INTER_VERSION}.zip"
EXTRACT_DIR="${TMP_DIR}/Inter-${INTER_VERSION}"

echo "Downloading Inter v${INTER_VERSION}..."
curl -fL --progress-bar -o "${ZIP_PATH}" "${DOWNLOAD_URL}"

echo "Extracting..."
unzip -q "${ZIP_PATH}" -d "${EXTRACT_DIR}"

# Python snippet that:
#   1. Strips emoji glyphs (U+2194–U+2BFF and U+1F000–U+1FBFF) from the font's
#      cmap so Flutter falls back to the system color emoji font instead of
#      rendering them as monochrome text glyphs from Inter.
#   2. Renames all "Inter"/"InterVariable" name-table records to "TwakeInter".
process_font() {
  local src="$1"
  local dst="$2"

  python3 - "${src}" "${dst}" <<'PYEOF'
import sys, re
from fontTools.ttLib import TTFont

# Unicode ranges whose glyphs Inter provides but should be rendered
# as color emoji by the system font instead.
EMOJI_RANGES = [
    (0x2194, 0x2BFF),   # Miscellaneous symbols, arrows, etc.
    (0x1F000, 0x1FBFF), # Emoji, pictographs, mahjong, etc.
]

src, dst = sys.argv[1], sys.argv[2]
font = TTFont(src)

# --- Step 1: strip emoji codepoints from every cmap subtable ---
removed = 0
for table in font["cmap"].tables:
    for start, end in EMOJI_RANGES:
        for cp in range(start, end + 1):
            if cp in table.cmap:
                del table.cmap[cp]
                removed += 1

print(f"  Removed {removed} emoji cmap entries from {src.split('/')[-1]}")

# --- Step 2: rename Inter → TwakeInter in the name table ---
for record in font["name"].names:
    value = record.toUnicode()
    updated = value.replace("InterVariable", "TwakeInter")
    updated = re.sub(r'\bInter\b', 'TwakeInter', updated)
    if updated != value:
        record.string = updated.encode(
            "utf-16-be" if record.isUnicode() else "latin-1",
            errors="replace",
        )

font.save(dst)
print(f"  Saved → {dst.split('/')[-1]}")
PYEOF
}

# Generate single variable font: TwakeInter.ttf
echo "Processing TwakeInter.ttf (variable font)..."
process_font "${EXTRACT_DIR}/InterVariable.ttf" "${OUT_DIR}/TwakeInter.ttf"

# Generate static weights from the desktop subfolder
echo "Processing static weights..."
declare -A WEIGHTS=(
  ["Inter-Regular.ttf"]="TwakeInter-Regular.ttf"
  ["Inter-Medium.ttf"]="TwakeInter-Medium.ttf"
  ["Inter-SemiBold.ttf"]="TwakeInter-SemiBold.ttf"
  ["Inter-Bold.ttf"]="TwakeInter-Bold.ttf"
)

for src_name in "${!WEIGHTS[@]}"; do
  dst_name="${WEIGHTS[$src_name]}"
  # Inter v4.x puts static TTFs under web/ or desktop/ depending on release
  src_path=""
  for subdir in "web" "desktop" ""; do
    candidate="${EXTRACT_DIR}/${subdir:+$subdir/}${src_name}"
    if [[ -f "${candidate}" ]]; then
      src_path="${candidate}"
      break
    fi
  done

  if [[ -z "${src_path}" ]]; then
    echo "  Warning: ${src_name} not found in archive, skipping."
    continue
  fi

  process_font "${src_path}" "${OUT_DIR}/${dst_name}"
done

echo "Cleaning up..."
rm -rf "${TMP_DIR}"

echo "Done. Files in ${OUT_DIR}/:"
ls -1 "${OUT_DIR}/"*.ttf
