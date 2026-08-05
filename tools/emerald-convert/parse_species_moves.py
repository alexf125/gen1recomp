#!/usr/bin/env python3
"""
parse_species_moves.py

Conservative extractor: scans pokeemerald source files for SPECIES_ and MOVE_ tokens and emits
simple JSON and Lua lists. This is a best-effort name list extractor to seed the conversion pipeline.

It does NOT guarantee perfect mapping (some tokens are used in other contexts) but provides a quick
lookup to drive the next phase of automated conversion.

Usage:
  python3 tools/emerald-convert/parse_species_moves.py --pokeemerald-path /path/to/pokeemerald --out-data data/generated

"""

import argparse
import json
import re
from pathlib import Path

SPECIES_RE = re.compile(r"\bSPECIES_([A-Z0-9_]+)\b")
MOVE_RE = re.compile(r"\bMOVE_([A-Z0-9_]+)\b")


def scan_tokens(root: Path):
    species = set()
    moves = set()
    for p in root.rglob('*'):
        if not p.is_file():
            continue
        if p.suffix.lower() not in ('.h', '.c', '.s', '.txt'):
            continue
        try:
            txt = p.read_text(errors='ignore')
        except Exception:
            continue
        for m in SPECIES_RE.finditer(txt):
            species.add(m.group(1))
        for m in MOVE_RE.finditer(txt):
            moves.add(m.group(1))
    return sorted(species), sorted(moves)


def write_json(outdir: Path, name: str, data):
    outdir.mkdir(parents=True, exist_ok=True)
    dest = outdir / (name + '.json')
    dest.write_text(json.dumps(data, indent=2))
    print('Wrote', dest)


def write_lua_list(outdir: Path, name: str, data):
    outdir.mkdir(parents=True, exist_ok=True)
    dest = outdir / (name + '.lua')
    with dest.open('w', encoding='utf-8') as f:
        f.write('return {
')
        for v in data:
            # keep original upper-case token as an identifier string
            f.write(f'  "{v}",\n')
        f.write('}\n')
    print('Wrote', dest)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--pokeemerald-path', required=True)
    ap.add_argument('--out-data', default='data/generated')
    args = ap.parse_args()

    root = Path(args.pokeemerald_path)
    if not root.exists():
        print('pokeemerald path not found:', root)
        return

    print('Scanning', root)
    species, moves = scan_tokens(root)
    print('Found species tokens:', len(species))
    print('Found move tokens:', len(moves))

    out = Path(args.out_data)
    write_json(out, 'pokemon_tokens', species)
    write_json(out, 'move_tokens', moves)
    write_lua_list(out, 'pokemon_tokens', species)
    write_lua_list(out, 'move_tokens', moves)

    print('\nSample species tokens (first 50):', species[:50])

if __name__ == '__main__':
    main()
