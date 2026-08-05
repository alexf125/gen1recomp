#!/bin/sh
# tools/export_graphics.sh
# Export graphics/tiles/palettes/cries using pokeemerald data + existing tools.
# This script assumes you have the pokeemerald repo checked out (or data path) and
# tools like grit, gba-image-tools, or other converters available in PATH.

set -euo pipefail
DATA_DIR=${1:-data}
OUT_DIR=${2:-exported_assets}
mkdir -p "$OUT_DIR"

echo "Exporting tiles/palettes from $DATA_DIR -> $OUT_DIR"

# Example: find .4bpp tiledata arrays (this is a placeholder step; adapt to your toolchain)
# Iterate over known files (pokeemerald-specific paths expected)
# This script should be customized to call actual conversion tools present in your environment.

# Placeholder: copy any PNG/TGA already present
find "$DATA_DIR" -type f \( -name '*.png' -o -name '*.tga' \) -exec cp {} "$OUT_DIR"/ \;

# TODO: Add calls to grit/gba-image-utils to convert raw GBA tiles+palettes to PNG/TGA
# e.g.
# gba2png --tiles tiles.bin --palette pal.bin -o "$OUT_DIR/tiles.png"

# Audio (cries) placeholder: copy .gba/.bin cries if present
find "$DATA_DIR" -type f -name '*.gba' -exec cp {} "$OUT_DIR"/ \; || true

echo "Export complete. Customize tools/export_graphics.sh to integrate your preferred converters." 
