#!/bin/sh
# scripts/import-assets.sh
# High-level pipeline to import headers, extract symbols, and export assets.
set -e
BASE=${1:-.}
PREP_OUT=build/preprocessed.i
SYMBOLS_OUT=build/symbols.json
ASSETS_OUT=build/assets

mkdir -p build

# Preprocess headers (adjust paths as needed)
if [ -f "$BASE/include/global.h" ]; then
  tools/preprocess_headers.sh "$BASE/include/global.h" > "$PREP_OUT"
else
  echo "Warning: $BASE/include/global.h not found; preprocessing first header in include/"
  FIRST=$(ls "$BASE/include" | head -n1)
  tools/preprocess_headers.sh "$BASE/include/$FIRST" > "$PREP_OUT"
fi

# Extract named arrays
python3 tools/extract_symbols.py "$PREP_OUT" -o "$SYMBOLS_OUT"

# Export graphics/audio using pokeemerald data layout
tools/export_graphics.sh "$BASE/data" "$ASSETS_OUT"

echo "Import pipeline finished. Outputs: $SYMBOLS_OUT, $ASSETS_OUT"
