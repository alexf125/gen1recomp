#!/bin/sh
# import-assets.sh - full import pipeline
# Preprocess headers, extract symbols, parse species, map species using schema,
# extract moves (or generate placeholder), convert graphics/cries, generate player sprite,
# convert maps (fallback to sample), and produce build outputs for the LÖVE preview.
set -euo pipefail
PE_ROOT=${1:-.}
BUILD_DIR=build
PREP_DIR="$BUILD_DIR/preprocessed"
PREP_ALL="$BUILD_DIR/preprocessed_all.i"
SYMBOLS_OUT="$BUILD_DIR/symbols.json"
SPECIES_OUT="$BUILD_DIR/species.json"
SPECIES_MAPPED_OUT="$BUILD_DIR/species_mapped.json"
MOVES_OUT="$BUILD_DIR/moves.json"
ASSETS_OUT="$BUILD_DIR/assets"
CRIES_OUT="$ASSETS_OUT/cries"

mkdir -p "$BUILD_DIR" "$PREP_DIR" "$ASSETS_OUT" "$CRIES_OUT"

# Preprocess headers under include/ and src/data/
echo "Preprocessing headers..."
if [ -d "$PE_ROOT/include" ]; then
  find "$PE_ROOT/include" -type f -name '*.h' -print0 | xargs -0 -n1 -I{} sh -c 'tools/preprocess_headers.sh "{}" > "$PREP_DIR/$(basename {}).i"'
fi
if [ -d "$PE_ROOT/src/data" ]; then
  find "$PE_ROOT/src/data" -type f -name '*.h' -print0 | xargs -0 -n1 -I{} sh -c 'tools/preprocess_headers.sh "{}" > "$PREP_DIR/$(basename {}).i"'
fi

# Concatenate all preprocessed files into one for scanning
cat "$PREP_DIR"/*.i > "$PREP_ALL" || true

# Extract named arrays
echo "Extracting symbols..."
python3 tools/extract_symbols.py --inputs "$PREP_ALL" --output "$SYMBOLS_OUT"

# Parse species info
echo "Parsing species table..."
python3 tools/parse_species.py --input "$SYMBOLS_OUT" --output "$SPECIES_OUT"

# Map species fields using schema
SCHEMA=tools/species_schema.json
if [ -f "$SCHEMA" ]; then
  echo "Mapping species fields using schema $SCHEMA"
  python3 tools/map_species_with_schema.py --input "$SPECIES_OUT" --schema "$SCHEMA" --output "$SPECIES_MAPPED_OUT"
else
  echo "Schema $SCHEMA not found; falling back to previous mapper"
  python3 tools/map_species_fields.py --input "$SPECIES_OUT" --output "$SPECIES_MAPPED_OUT"
fi

# Extract moves (heuristic) and fallback to placeholder if extraction fails
echo "Extracting moves..."
python3 tools/parse_moves.py --symbols "$SYMBOLS_OUT" --out "$MOVES_OUT" || true
if [ ! -f "$MOVES_OUT" ] || [ ! -s "$MOVES_OUT" ]; then
  echo "No moves extracted; generating placeholder moves.json"
  python3 tools/generate_moves_placeholder.py "$MOVES_OUT"
fi

# Export graphics/audio using pokeemerald data layout
echo "Converting graphics..."
python3 tools/convert_gba_graphics.py --symbols "$SYMBOLS_OUT" --out "$ASSETS_OUT"

echo "Converting cries (placeholders)..."
python3 tools/convert_cries.py --symbols "$SYMBOLS_OUT" --out "$CRIES_OUT"

# If no tiles were produced by conversion, generate a sample
if [ ! -f "$ASSETS_OUT/tiles.png" ]; then
  echo "No converted tiles found -- generating sample tiles"
  python3 tools/generate_sample_tiles.py "$ASSETS_OUT"
fi

# Generate a placeholder player sprite if missing
if [ ! -f "$ASSETS_OUT/player.png" ]; then
  echo "Generating placeholder player sprite..."
  python3 tools/generate_player_sprite.py "$ASSETS_OUT/player.png"
fi

# Convert maps
python3 tools/convert_maps.py --symbols "$SYMBOLS_OUT" --out "$BUILD_DIR/maps" --tiles "$ASSETS_OUT/tiles_meta.json"

# If convert_maps did not produce maps, ensure a fallback sample map exists at build/map.json
MAP_OUT="$BUILD_DIR/map.json"
if [ ! -d "$BUILD_DIR/maps" ] || [ -z "$(ls -A $BUILD_DIR/maps 2>/dev/null || true)" ]; then
  echo "No maps found in build/maps; creating sample map at $MAP_OUT"
  cat > "$MAP_OUT" <<EOF
{
  "width": 16,
  "height": 12,
  "tileset": "assets/tiles.png",
  "tile_width": 8,
  "tile_height": 8,
  "layers": [
    [
EOF
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
else
  echo "Maps found in build/maps/; using those for preview."
fi

echo "Import pipeline finished. Outputs: $SYMBOLS_OUT, $SPECIES_OUT, $SPECIES_MAPPED_OUT, $MOVES_OUT, $ASSETS_OUT, $BUILD_DIR/maps"
