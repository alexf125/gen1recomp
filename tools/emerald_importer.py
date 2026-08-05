#!/usr/bin/env python3
"""
tools/emerald_importer.py

Quick-and-dirty importer to extract simple data blocks from a pokeemerald checkout
and emit JSON files that gen1recomp can load. This is intentionally conservative — it
extracts #define constants and top-level initializer lists (arrays) by simple regex
heuristics. It is not a full C parser but is a practical starting point you can iterate on.

Usage:
  python3 tools/emerald_importer.py --src /path/to/pokeemerald --out data/emerald

It will look for a handful of common data headers (species_info.h, pokedex_entries.h,
level_up_learnsets.h, tmhm_learnsets.h, tutor_learnsets.h) and produce JSON files.

Note: You should run this against a LOCAL clone of alexf125/pokeemerald. This script
expects plain text .h files (not preprocessed). If you want more robust parsing, run
a C preprocessor (gcc -E) on the headers first and point --src to the preprocessed
output directory.
"""

import argparse
import json
import os
import re
import sys

# Files we try to extract from the pokeemerald repo. Key: source path relative to repo root,
# value: output json filename.
HEADER_MAP = {
    'src/data/pokemon/species_info.h': 'species_info.json',
    'src/data/pokemon/pokedex_entries.h': 'pokedex_entries.json',
    'src/data/pokemon/level_up_learnsets.h': 'level_up_learnsets.json',
    'src/data/pokemon/tmhm_learnsets.h': 'tmhm_learnsets.json',
    'src/data/pokemon/tutor_learnsets.h': 'tutor_learnsets.json',
    'src/data/pokemon/egg_moves.h': 'egg_moves.json',
}

DEFINE_RE = re.compile(r'^\s*#\s*define\s+(\w+)\s+(.+)$')

# Find a top-level initializer (naive): find first occurrence of '={' and capture until '};'
INIT_RE = re.compile(r'=\s*\{', re.M)

def read_file(path):
    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
        return f.read()


def extract_defines(text):
    defines = {}
    for line in text.splitlines():
        m = DEFINE_RE.match(line)
        if m:
            name, val = m.group(1), m.group(2).strip()
            # strip comments
            val = re.sub(r'/\*.*?\*/', '', val)
            val = re.sub(r'//.*$', '', val).strip()
            defines[name] = val
    return defines


def find_initializer_blocks(text):
    # Very naive: find all occurrences of "{ ... };" and return the inner text.
    blocks = []
    i = 0
    while True:
        m = INIT_RE.search(text, i)
        if not m:
            break
        start = m.end() - 1  # position at the '{'
        depth = 0
        j = start
        while j < len(text):
            if text[j] == '{':
                depth += 1
            elif text[j] == '}':
                depth -= 1
                if depth == 0:
                    # check for the following ';'
                    end = j
                    # include trailing characters up to '};'
                    # return the inner block
                    blocks.append(text[start+1:end])
                    i = j + 1
                    break
            j += 1
        else:
            break
    return blocks


def tokenize_c_values(block_text):
    # Convert a C initializer block into a nested Python structure where possible.
    # This is intentionally permissive: we convert numbers and simple strings.
    # We return a list of entries (top-level comma-separated items).
    tokens = []
    cur = ''
    depth = 0
    i = 0
    items = []
    while i < len(block_text):
        ch = block_text[i]
        if ch == '{':
            # find matching }
            depth = 1
            j = i + 1
            while j < len(block_text):
                if block_text[j] == '{':
                    depth += 1
                elif block_text[j] == '}':
                    depth -= 1
                    if depth == 0:
                        break
                j += 1
            inner = block_text[i+1:j]
            items.append(tokenize_c_values(inner))
            i = j + 1
            # skip possible comma/space
            while i < len(block_text) and block_text[i] in ', \t\r\n':
                i += 1
            continue
        elif ch == ',':
            if cur.strip() != '':
                items.append(cur.strip())
            cur = ''
            i += 1
            continue
        else:
            cur += ch
        i += 1
    if cur.strip() != '':
        items.append(cur.strip())
    # post-process items: convert numeric strings to numbers, strip trailing 'u' or 'UL'
    def conv(x):
        if isinstance(x, list):
            return [conv(e) for e in x]
        s = x
        # remove casts like (u8)
        s = re.sub(r'\([^)]+\)', '', s).strip()
        # remove trailing U/L chars
        s_clean = re.sub(r'[uUlL]+$', '', s)
        # strip quotes
        if s_clean.startswith('"') and s_clean.endswith('"'):
            return s_clean[1:-1]
        # try int
        try:
            if s_clean.startswith('0x') or s_clean.startswith('0X'):
                return int(s_clean, 16)
            return int(s_clean)
        except Exception:
            # fallback: return original stripped string
            return s.strip()
    return [conv(it) for it in items]


def process_header(src_path, dst_path):
    text = read_file(src_path)
    defines = extract_defines(text)
    blocks = find_initializer_blocks(text)
    data = {'defines': defines, 'initializer_blocks_count': len(blocks), 'initializers': []}
    for b in blocks:
        try:
            parsed = tokenize_c_values(b)
        except Exception as e:
            parsed = {'error': str(e), 'raw': b[:200]}
        data['initializers'].append(parsed)
    with open(dst_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)
    print(f'Wrote {dst_path} (defines={len(defines)}, blocks={len(blocks)})')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--src', required=True, help='Path to local pokeemerald checkout')
    ap.add_argument('--out', required=True, help='Output directory inside gen1recomp (data/emerald)')
    ap.add_argument('--files', nargs='*', help='Optional subset of HEADER_MAP keys to process')
    args = ap.parse_args()

    src = os.path.abspath(args.src)
    out = os.path.abspath(args.out)
    os.makedirs(out, exist_ok=True)

    files = HEADER_MAP if not args.files else {k: HEADER_MAP[k] for k in args.files if k in HEADER_MAP}
    for rel, outname in files.items():
        src_path = os.path.join(src, rel.replace('/', os.sep))
        if not os.path.exists(src_path):
            print(f'Warning: {src_path} not found, skipping', file=sys.stderr)
            continue
        dst_path = os.path.join(out, outname)
        process_header(src_path, dst_path)

if __name__ == '__main__':
    main()
