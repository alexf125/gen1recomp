#!/usr/bin/env python3
"""
tools/convert_gba_graphics.py (updated)

Convert GBA 4bpp tile arrays and 15-bit palettes found in build/symbols.json into PNG
tilesheets and palette metadata consumable by the LÖVE frontend.

Improvements vs prior prototype:
- Detect palettes and tilesets and, when both are present, apply palettes to tiles so
  PNGs are colorized correctly instead of grayscale placeholders.
- Produce a single canonical tiles.png (first tileset found) and tiles_meta.json that
  describes tile size and count for the renderer.

Usage:
  python3 tools/convert_gba_graphics.py --symbols build/symbols.json --out build/assets
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
    if not arr:
        return False
    if any(not isinstance(v, int) for v in arr):
        return False
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
    # palettes are typically length multiple of 16
    return len(arr) >= 1 and (len(arr) % 16 == 0)


def gba_color_to_rgb(val):
    r = val & 0x1F
    g = (val >> 5) & 0x1F
    b = (val >> 10) & 0x1F
    r = (r * 255) // 31
    g = (g * 255) // 31
    b = (b * 255) // 31
    return (r, g, b)


def make_tilesheet_bytes(bytes_arr, tile_w=8, tile_h=8, columns=16):
    num_tiles = len(bytes_arr) // 32
    cols = min(columns, num_tiles) if num_tiles>0 else 1
    rows = (num_tiles + cols - 1) // cols
    # create 2D array of pal indexes for each pixel
    tiles = []
    for t in range(num_tiles):
        tile_bytes = bytes_arr[t*32:(t+1)*32]
        # create 8x8 tile pal index array
        tile_px = [[0]*tile_w for _ in range(tile_h)]
        for y in range(8):
            for x in range(8):
                byte_index = y*4 + (x//2)
                b = tile_bytes[byte_index]
                if x % 2 == 0:
                    pal_index = b & 0x0F
                else:
                    pal_index = (b >> 4) & 0x0F
                tile_px[y][x] = pal_index
        tiles.append(tile_px)
    return tiles, cols, rows


def tiles_and_palette_to_image(tiles, palette_rgb, cols, tile_w=8, tile_h=8):
    rows = (len(tiles) + cols - 1) // cols
    img_w = cols * tile_w
    img_h = rows * tile_h
    img = Image.new('RGBA', (img_w, img_h), (0,0,0,0))
    pixels = img.load()
    for t, tile in enumerate(tiles):
        col = t % cols
        row = t // cols
        for y in range(tile_h):
            for x in range(tile_w):
                pal_idx = tile[y][x]
                # clamp palette index
                if pal_idx < 0 or pal_idx >= len(palette_rgb):
                    color = (0,0,0,0)
                else:
                    r,g,b = palette_rgb[pal_idx]
                    color = (r,g,b,255)
                pixels[col*tile_w + x, row*tile_h + y] = color
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
    tilesets = {}

    # collect candidates
    for s in symbols:
        name = s.get('name')
        parsed = s.get('parsed_sample')
        if parsed is None:
            continue
        arr = flatten(parsed)
        if is_palette_array(arr):
            palettes[name] = arr
        elif is_tile_array(arr):
            tilesets[name] = arr

    # If no palettes, leave empty
    palette_rgb = None
    chosen_palette_name = None
    if palettes:
        # pick a palette (heuristic: choose the largest one)
        chosen_palette_name = max(palettes.keys(), key=lambda k: len(palettes[k]))
        pal_arr = palettes[chosen_palette_name]
        palette_rgb = [gba_color_to_rgb(int(v)) for v in pal_arr]
        with open(os.path.join(out_dir, f'palette_{chosen_palette_name}.json'), 'w', encoding='utf-8') as out:
            json.dump({'name': chosen_palette_name, 'colors': palette_rgb}, out)
        print('Wrote palette json for', chosen_palette_name)

    tiles_written = []
    # produce tilesheets; if palette exists, colorize using it
    for name, arr in tilesets.items():
        tiles, cols, rows = make_tilesheet_bytes(arr, tile_w=8, tile_h=8, columns=16)
        if palette_rgb:
            img = tiles_and_palette_to_image(tiles, palette_rgb, cols, tile_w=8, tile_h=8)
        else:
            # fallback grayscale using pal index
            img = Image.new('RGBA', (cols*8, rows*8), (0,0,0,0))
            px = img.load()
            for t, tile in enumerate(tiles):
                col = t % cols
                row = t // cols
                for y in range(8):
                    for x in range(8):
                        pal_idx = tile[y][x]
                        gray = int(255 * pal_idx / 15)
                        px[col*8 + x, row*8 + y] = (gray,gray,gray,255)
        pngname = f'tiles_{name}.png'
        img_path = os.path.join(out_dir, pngname)
        img.save(img_path)
        meta = {
            'name': name,
            'tileset': pngname,
            'tile_width': 8,
            'tile_height': 8,
            'tiles': len(arr)//32,
            'palette': chosen_palette_name if chosen_palette_name else None
        }
        with open(os.path.join(out_dir, f'tiles_{name}_meta.json'), 'w', encoding='utf-8') as out:
            json.dump(meta, out, indent=2)
        tiles_written.append((name, img_path))
        print('Wrote tileset:', img_path)

    # Create a canonical tiles.png (pick first tiles_written) and a tiles_meta.json for the renderer
    if tiles_written:
        first_name, first_path = tiles_written[0]
        # copy/rename to tiles.png
        canonical = os.path.join(out_dir, 'tiles.png')
        # overwrite existing
        from shutil import copyfile
        copyfile(first_path, canonical)
        # write meta
        meta_file = os.path.join(out_dir, 'tiles_meta.json')
        with open(os.path.join(out_dir, f'tiles_{first_name}_meta.json'), 'r', encoding='utf-8') as fmeta:
            m = json.load(fmeta)
        # add palette info if available
        if palette_rgb:
            m['palette'] = chosen_palette_name
        with open(meta_file, 'w', encoding='utf-8') as fmetaout:
            json.dump(m, fmetaout, indent=2)
        print('Wrote canonical tiles.png and tiles_meta.json')
    else:
        print('No tile arrays detected; no tiles written')

if __name__ == '__main__':
    main()
