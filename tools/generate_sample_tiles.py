#!/usr/bin/env python3
"""
tools/generate_sample_tiles.py (updated to 8x8 tiles)
"""
from PIL import Image, ImageDraw
import sys
import json
import os

OUT_DIR = sys.argv[1] if len(sys.argv)>1 else 'build/assets'
os.makedirs(OUT_DIR, exist_ok=True)

TILE_SIZE = 8
COLUMNS = 8
ROWS = 8
W = TILE_SIZE * COLUMNS
H = TILE_SIZE * ROWS
img = Image.new('RGBA', (W, H), (0,0,0,0))
d = ImageDraw.Draw(img)

colors = [(255,0,0),(0,255,0),(0,0,255),(255,255,0),(255,0,255),(0,255,255),(200,100,50),(120,50,200)]
for r in range(ROWS):
    for c in range(COLUMNS):
        i = r * COLUMNS + c
        col = colors[i % len(colors)]
        x0 = c * TILE_SIZE
        y0 = r * TILE_SIZE
        d.rectangle([x0,y0,x0+TILE_SIZE-1,y0+TILE_SIZE-1], fill=col+(255,))
        for k in range(2):
            d.line([x0+k, y0, x0+TILE_SIZE-1, y0+k], fill=(0,0,0,60))

out_png = os.path.join(OUT_DIR, 'tiles.png')
img.save(out_png)

meta = {
    'tileset': 'tiles.png',
    'tile_width': TILE_SIZE,
    'tile_height': TILE_SIZE,
    'columns': COLUMNS,
    'rows': ROWS,
}
with open(os.path.join(OUT_DIR, 'tiles.json'), 'w', encoding='utf-8') as f:
    json.dump(meta, f, indent=2)

print('Generated sample tiles:', out_png)
