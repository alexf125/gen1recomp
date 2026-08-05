#!/usr/bin/env python3
"""
tools/convert_gba_graphics.py

Convert GBA 4bpp tile arrays and 15-bit palettes found in build/symbols.json into PNG
tilesheets and palette metadata consumable by the LÖVE frontend.

Heuristics:
 - Tile arrays: flattened numeric sequence whose length is a multiple of 32 (32 bytes per 8x8 4bpp tile)
 - Palette arrays: flattened numeric sequence of 16-bit values (<= 0x7FFF); treated as palettes

Usage:
  python3 tools/convert_gba_graphics.py --symbols build/symbols.json --out build/assets

This is a prototype converter. It will generate tiles_{symbol}.png and palettes_{symbol}.json
for any detected arrays.
"""

import argparse
import json
import os
from PIL import Image


def flatten(x):
    out = []
    if isinstance(x, list):
        for e in x:
            out.extend(flatten(e))
    else:
        out.append(x)
    return out


def is_tile_array(arr):
    # tile is 32 bytes per 8x8 4bpp
    if not arr:
        return False
    if any(not isinstance(v, int) for v in arr):
        return False
    # typical byte values 0..255
    if any(v < 0 or v > 255 for v in arr):
        return False
    return (len(arr) % 32) == 0 and len(arr) >= 32


def is_palette_array(arr):
    if not arr:
        return False
    if any(not isinstance(v, int) for v in arr):
        return False
    if any(v < 0 or v > 0x7FFF for v in arr):
        return False
    # palette lengths often 16, 256, etc.
    return len(arr) >= 1 and (len(arr) <= 256)


def gba_color_to_rgb(val):
    # GBA 15-bit: bits 0-4 red, 5-9 green, 10-14 blue
    r = val & 0x1F
    g = (val >> 5) & 0x1F
    b = (val >> 10) & 0x1F
    # scale to 0-255
    r = (r * 255) // 31
    g = (g * 255) // 31
    b = (b * 255) // 31
    return (r, g, b)


def make_tilesheet(bytes_arr, tile_w=8, tile_h=8, columns=16):
    # bytes_arr is a list of byte values
    num_tiles = len(bytes_arr) // 32
    cols = min(columns, num_tiles) if num_tiles>0 else 1
    rows = (num_tiles + cols - 1) // cols
    img_w = cols * tile_w
    img_h = rows * tile_h
    img = Image.new('RGBA', (img_w, img_h), (0,0,0,0))
    pixels = img.load()

    for t in range(num_tiles):
        tile_bytes = bytes_arr[t*32:(t+1)*32]
        col = t % cols
        row = t // cols
        for y in range(8):
            for x in range(8):
                # byte index for row y: 4 bytes per row (8 pixels, 2 per byte)
                byte_index = y*4 + (x//2)
                b = tile_bytes[byte_index]
                if x % 2 == 0:
                    pal_index = b & 0x0F
                else:
                    pal_index = (b >> 4) & 0x0F
                # set pixel to palette index as placeholder (we'll replace with actual palette later)
                # encode pal_index into grayscale for now
                px = col*tile_w + x
                py = row*tile_h + y
                pixels[px,py] = (pal_index*16, pal_index*16, pal_index*16, 255)
    return img


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--symbols', required=True)
    p.add_argument('--out', required=True)
    args = p.parse_args()

    out_dir = args.out
    os.makedirs(out_dir, exist_ok=True)

    with open(args.symbols, 'r', encoding='utf-8') as f:
        data = json.load(f)
    symbols = data.get('gen1recomp', {}).get('symbols', [])

    palettes = {}
    tiles_found = []

    # First pass: find palettes
    for s in symbols:
        name = s.get('name')
        parsed = s.get('parsed_sample')
        if parsed is None:
            continue
        arr = flatten(parsed)
        if is_palette_array(arr):
            palettes[name] = arr
            # write palette json
            pal_rgb = [gba_color_to_rgb(int(v)) for v in arr]
            with open(os.path.join(out_dir, f'palette_{name}.json'), 'w', encoding='utf-8') as out:
                json.dump({'name': name, 'colors': pal_rgb}, out)
            print('Wrote palette:', name)

    # Second pass: find tiles
    for s in symbols:
        name = s.get('name')
        parsed = s.get('parsed_sample')
        if parsed is None:
            continue
        arr = flatten(parsed)
        if is_tile_array(arr):
            # convert to tilesheet image
            img = make_tilesheet(arr, tile_w=8, tile_h=8, columns=16)
            pngname = f'tiles_{name}.png'
            img_path = os.path.join(out_dir, pngname)
            img.save(img_path)
            meta = {
                'name': name,
                'tileset': pngname,
                'tile_width': 8,
                'tile_height': 8,
                'tiles': len(arr)//32
            }
            with open(os.path.join(out_dir, f'tiles_{name}_meta.json'), 'w', encoding='utf-8') as out:
                json.dump(meta, out, indent=2)
            tiles_found.append(name)
            print('Wrote tileset:', img_path)

    if not tiles_found:
        print('No tile arrays detected in symbols.json')
    else:
        print('Tiles processed:', tiles_found)

if __name__ == '__main__':
    main()
