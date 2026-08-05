#!/bin/sh
# scripts/import-assets.sh (improved)
# Usage: scripts/import-assets.sh /path/to/pokeemerald
set -euo pipefail
PE_ROOT=${1:-.}
BUILD_DIR=build
PREP_DIR="$BUILD_DIR/preprocessed"
PREP_ALL="$BUILD_DIR/preprocessed_all.i"
SYMBOLS_OUT="$BUILD_DIR/symbols.json"
ASSETS_OUT="$BUILD_DIR/assets"

mkdir -p "$BUILD_DIR" "$PREP_DIR" "$ASSETS_OUT"

# Preprocess headers under include/ and src/data/ (if present)
echo "Preprocessing headers..."
find "$PE_ROOT/include" -type f -name '*.h' -print0 2>/dev/null | xargs -0 -n1 -I{} sh -c 'tools/preprocess_headers.sh "{}" > "$PREP_DIR/$(basename {}).i"'

# Concatenate all preprocessed files into one for scanning
cat "$PREP_DIR"/*.i > "$PREP_ALL" || true

# Extract named arrays (scan for many symbols). You can pass --names to limit.
echo "Extracting symbols..."
python3 tools/extract_symbols.py --inputs "$PREP_ALL" --output "$SYMBOLS_OUT"

# Export graphics/audio using pokeemerald data layout
echo "Exporting graphics/audio..."
tools/export_graphics.sh "$PE_ROOT" "$ASSETS_OUT"

# Generate a simple sample map JSON that references tiles.json
MAP_OUT="$BUILD_DIR/map.json"
cat > "$MAP_OUT" <<EOF
{
  "width": 16,
  "height": 12,
  "tileset": "assets/tiles.png",
  "tile_width": 16,
  "tile_height": 16,
  "layers": [
    [
EOF
# generate a simple checker pattern
for y in $(seq 0 11); do
  echo -n "[" >> "$MAP_OUT"
  for x in $(seq 0 15); do
    idx=$(( (x + y) % 64 ))
    if [ $x -lt 15 ]; then
      echo -n "$idx, " >> "$MAP_OUT"
    else
      echo -n "$idx" >> "$MAP_OUT"
    fi
  done
  if [ $y -lt 11 ]; then
    echo "]," >> "$MAP_OUT"
  else
    echo "]" >> "$MAP_OUT"
  fi
done
cat >> "$MAP_OUT" <<EOF
    ]
  ]
}
EOF

echo "Import pipeline finished. Outputs: $SYMBOLS_OUT, $ASSETS_OUT, $MAP_OUT"
