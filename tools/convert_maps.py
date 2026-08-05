#!/usr/bin/env python3
"""
tools/convert_maps.py

Convert map data for the LÖVE frontend. This is a pragmatic converter:
- If it finds map-like arrays in build/symbols.json it will attempt to interpret them.
- Otherwise it emits a sample map JSON under build/maps/sample_map.json using the
  canonical tiles_meta.json to choose tile counts and sizes.

Usage:
  python3 tools/convert_maps.py --symbols build/symbols.json --out build/maps --tiles build/assets/tiles_meta.json

The produced map JSON schema:
{
  "id": "sample",
  "name": "sample",
  "width": 16,
  "height": 12,
  "tile_width": 8,
  "tile_height": 8,
  "tileset": "assets/tiles.png",
  "layers": [ [ [row0], [row1], ... ] ]
}

This is a generator for the MVP. Later we can add direct parsing of pokeemerald map tables.
"""

import argparse
import json
import os
import math

p = argparse.ArgumentParser()
p.add_argument('--symbols', required=True)
p.add_argument('--out', required=True)
p.add_argument('--tiles', default='build/assets/tiles_meta.json')
args = p.parse_args()

os.makedirs(args.out, exist_ok=True)

# read symbols
with open(args.symbols, 'r', encoding='utf-8') as f:
    syms = json.load(f)
symbols = syms.get('gen1recomp', {}).get('symbols', [])

# try to find tile count from tiles_meta
tile_width = 8
tile_height = 8
tileset_ref = 'assets/tiles.png'
num_tiles = None
if os.path.exists(args.tiles):
    with open(args.tiles, 'r', encoding='utf-8') as f:
        tmeta = json.load(f)
    tile_width = tmeta.get('tile_width', tile_width)
    tile_height = tmeta.get('tile_height', tile_height)
    tileset_ref = tmeta.get('tileset', tileset_ref)
    num_tiles = tmeta.get('tiles')

# Attempt to find map-like arrays in symbols (heuristic: name contains 'Map' and length sizeable)
map_candidates = []
for s in symbols:
    name = s.get('name','')
    parsed = s.get('parsed_sample')
    if not parsed:
        continue
    # flatten simple
    flat = []
    def _flatten(x):
        if isinstance(x, list):
            for e in x:
                _flatten(e)
        else:
            flat.append(x)
    _flatten(parsed)
    if 'map' in name.lower() and len(flat) >= 64:
        map_candidates.append({'name':name,'flat':flat})

if map_candidates:
    # make simple maps from candidates (assume flat is sequence of tile indices)
    for i, cand in enumerate(map_candidates):
        flat = cand['flat']
        # choose width as nearest power-of-two or 32
        guess_width = int(math.sqrt(len(flat)))
        if guess_width < 8:
            guess_width = 16
        guess_height = int(len(flat) / guess_width)
        if guess_height < 1:
            guess_height = 16
        # build rows
        rows = []
        for r in range(guess_height):
            row = []
            for c in range(guess_width):
                idx = r*guess_width + c
                if idx < len(flat):
                    row.append(int(flat[idx]) if isinstance(flat[idx], int) else 0)
                else:
                    row.append(0)
            rows.append(row)
        mapobj = {
            'id': cand['name'],
            'name': cand['name'],
            'width': guess_width,
            'height': guess_height,
            'tile_width': tile_width,
            'tile_height': tile_height,
            'tileset': tileset_ref,
            'layers': [rows]
        }
        outp = os.path.join(args.out, f'map_{cand["name"]}.json')
        with open(outp, 'w', encoding='utf-8') as f:
            json.dump(mapobj, f, indent=2)
        print('Wrote map from symbol:', outp)
else:
    # No candidates: write a sample map
    width = 16
    height = 12
    layers = []
    # generate two layers: base and object
    for layern in range(2):
        layer = []
        for y in range(height):
            row = []
            for x in range(width):
                # choose an index based on position
                idx = (x + y*width + layern*3) % (num_tiles or 64)
                row.append(idx)
            layer.append(row)
        layers.append(layer)
    mapobj = {
        'id': 'sample_map',
        'name': 'sample_map',
        'width': width,
        'height': height,
        'tile_width': tile_width,
        'tile_height': tile_height,
        'tileset': tileset_ref,
        'layers': layers
    }
    outp = os.path.join(args.out, 'sample_map.json')
    with open(outp, 'w', encoding='utf-8') as f:
        json.dump(mapobj, f, indent=2)
    print('Wrote sample map:', outp)

print('convert_maps.py: done')
