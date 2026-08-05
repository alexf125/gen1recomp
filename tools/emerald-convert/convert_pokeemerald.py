#!/usr/bin/env python3
"""
convert_pokeemerald.py

Initial conversion skeleton: inspect pokeemerald repo contents and produce a small mapping + sample JSON outputs.

This script is intentionally conservative: it will not modify gen1recomp files until individual writers are implemented.

"""

import argparse
import json
import os
import re
from pathlib import Path


ARRAY_RE = re.compile(r"(?P<type>const\s+\w+\s+)?(?P<name>[A-Za-z0-9_]+)\s*\[\s*\]\s*=\s*\{(?P<body>.*?)\};", re.S)
C_ARRAY_SIMPLE_RE = re.compile(r"(?P<name>[A-Za-z0-9_]+)\s*=\s*\{(?P<body>.*?)\}", re.S)


def find_pokeemerald_files(root: Path):
    # yield important directories
    for p in root.glob('**/*'):
        yield p


def extract_c_arrays(text: str):
    arrays = {}
    for m in ARRAY_RE.finditer(text):
        name = m.group('name')
        body = m.group('body')
        arrays[name] = body.strip()
    # fallback simple matches
    for m in C_ARRAY_SIMPLE_RE.finditer(text):
        name = m.group('name')
        if name not in arrays:
            arrays[name] = m.group('body').strip()
    return arrays


def parse_simple_int_list(body: str):
    # parse numbers separated by commas, ignoring comments
    nums = re.findall(r"-?0x[0-9A-Fa-f]+|-?\d+", body)
    out = []
    for n in nums:
        try:
            if n.startswith(('0x','-0x')):
                out.append(int(n, 16))
            else:
                out.append(int(n, 10))
        except Exception:
            pass
    return out


def scan_for_key_files(root: Path):
    candidates = {
        'species_headers': [],
        'moves_headers': [],
        'items_headers': [],
        'tilesets': [],
        'maps': [],
        'scripts': [],
        'random_c': None,
    }
    for p in root.glob('**/*'):
        if p.is_file():
            name = p.name.lower()
            if 'pokemon' in name and (name.endswith('.h') or name.endswith('.c') or 'pokemon' in p.parts):
                candidates['species_headers'].append(str(p))
            if 'move' in name and (name.endswith('.h') or name.endswith('.c')):
                candidates['moves_headers'].append(str(p))
            if name == 'items.h' or 'item' in name and name.endswith('.h'):
                candidates['items_headers'].append(str(p))
            if 'tileset' in name:
                candidates['tilesets'].append(str(p))
            if name in ('maps.s',) or p.parts and 'data' in p.parts and 'maps' in p.parts:
                if 'maps' in str(p):
                    candidates['maps'].append(str(p))
            if name.endswith('.s') and 'script' in name:
                candidates['scripts'].append(str(p))
            if p.name == 'random.c':
                candidates['random_c'] = str(p)
    return candidates


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--pokeemerald-path', required=True)
    ap.add_argument('--out-data', default='data/generated')
    ap.add_argument('--out-assets', default='assets/generated')
    args = ap.parse_args()

    pe = Path(args.pokeemerald_path)
    if not pe.exists():
        print('pokeemerald path not found:', pe)
        return

    print('Scanning pokeemerald at', pe)
    candidates = scan_for_key_files(pe)
    print('\nFound candidate sources:')
    for k, v in candidates.items():
        print(' -', k, ':', (len(v) if isinstance(v, list) else v))

    # Example: parse random.c to discover PRNG implementation
    rng_file = candidates.get('random_c')
    if rng_file:
        print('\nReading RNG implementation from', rng_file)
        txt = Path(rng_file).read_text(errors='ignore')
        # crude detection of LCG or other; look for "seed" usage
        if 'seed' in txt or 'srand' in txt or 'Random' in txt:
            print(' - RNG file looks valid; include for direct port')

    # Example parse: look for data/json exports under src/data/wild_encounters.json
    wild_json = pe / 'src' / 'data' / 'wild_encounters.json'
    if wild_json.exists():
        print('\nFound wild_encounters.json; writing to out-data/wild_encounters.json')
        out_path = Path(args.out_data)
        out_path.mkdir(parents=True, exist_ok=True)
        dest = out_path / 'wild_encounters.json'
        dest.write_text(wild_json.read_text())
        print(' - wrote', dest)

    # Very small sample: extract named arrays from a sample header (items.h if present)
    sample = None
    if candidates['items_headers']:
        sample = Path(candidates['items_headers'][0])
    elif candidates['species_headers']:
        sample = Path(candidates['species_headers'][0])
    if sample:
        print('\nParsing sample header:', sample)
        txt = sample.read_text(errors='ignore')
        arrays = extract_c_arrays(txt)
        if arrays:
            print(' - found arrays:', list(arrays.keys())[:10])
            # persist a tiny JSON with the first array parsed as ints where possible
            first_name, first_body = next(iter(arrays.items()))
            ints = parse_simple_int_list(first_body)
            out = { 'source': str(sample), 'array_name': first_name, 'ints_sample': ints[:200] }
            dest = Path(args.out_data) / (first_name + '.json')
            Path(args.out_data).mkdir(parents=True, exist_ok=True)
            dest.write_text(json.dumps(out, indent=2))
            print(' - wrote sample parsed array to', dest)
        else:
            print(' - no C arrays detected in sample')

    print('\nScan complete. Next: implement dedicated parsers for species/moves/items and image extraction for tilesets.')


if __name__ == '__main__':
    main()
