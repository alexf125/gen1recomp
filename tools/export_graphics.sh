#!/bin/sh
# tools/export_graphics.sh (updated)
set -euo pipefail
DATA_DIR=${1:-.}
OUT_DIR=${2:-build/assets}
mkdir -p "$OUT_DIR"

# If there are already PNG/TGA in DATA_DIR, copy them; otherwise generate sample tiles
found=0
for ext in png tga; do
  if find "$DATA_DIR" -type f -iname "*.$ext" | grep -q .; then
    found=1
    break
  fi
done

if [ "$found" -eq 1 ]; then
  echo "Copying existing PNG/TGA assets from $DATA_DIR to $OUT_DIR"
  find "$DATA_DIR" -type f \( -iname '*.png' -o -iname '*.tga' \) -exec cp {} "$OUT_DIR"/ \;
  exit 0
fi

# Fallback: generate a sample tileset using Python + Pillow
if command -v python3 >/dev/null 2>&1; then
  echo "No existing images found; generating sample tileset into $OUT_DIR"
  python3 tools/generate_sample_tiles.py "$OUT_DIR"
else
  echo "No python3 available to generate sample tiles. Provide converted tiles in $OUT_DIR" >&2
  exit 1
fi
