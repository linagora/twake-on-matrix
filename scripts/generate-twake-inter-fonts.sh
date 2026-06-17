#!/usr/bin/env bash
# generate-twake-inter-fonts.sh
#
# Downloads the latest Inter font release and produces TwakeInter.ttf
# (a variable font) with font metadata renamed from "Inter" to "TwakeInter".
# Output is placed in assets/google_fonts/.
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

# Python snippet that renames Inter → TwakeInter in all name table records
rename_font() {
  local src="$1"
  local dst="$2"

  python3 - "${src}" "${dst}" <<'PYEOF'
import sys, re
from fontTools.ttLib import TTFont

src, dst = sys.argv[1], sys.argv[2]
font = TTFont(src)

for record in font["name"].names:
    value = record.toUnicode()
    # Replace "InterVariable" first, then bare "Inter"
    updated = value.replace("InterVariable", "TwakeInter")
    updated = re.sub(r'\bInter\b', 'TwakeInter', updated)
    if updated != value:
        record.string = updated.encode(
            "utf-16-be" if record.isUnicode() else "latin-1",
            errors="replace",
        )

font.save(dst)
print(f"  {src.split('/')[-1]} → {dst.split('/')[-1]}")
PYEOF
}

# Generate single variable font: TwakeInter.ttf
echo "Generating TwakeInter.ttf (variable font) in ${OUT_DIR}/"
rename_font "${EXTRACT_DIR}/InterVariable.ttf" "${OUT_DIR}/TwakeInter.ttf"

echo "Cleaning up..."
rm -rf "${TMP_DIR}"

echo "Done. Files in ${OUT_DIR}/:"
ls -1 "${OUT_DIR}/"*.ttf
