#!/usr/bin/env python3
"""
tools/map_species_fields.py

Map parsed species initializer arrays into a best-effort structured JSON schema for the LÖVE frontend.
This uses heuristics: the first six numbers are treated as base stats (HP, Atk, Def, Spd, SpAtk, SpDef).
Subsequent fields are guessed where values fall into expected ranges (types 0-17, catch rate 0-255, etc.).

Usage:
  python3 tools/map_species_fields.py --input build/species.json --output build/species_mapped.json

This is a heuristic mapper; refine the field order if you have confirmed struct layout.
"""

import argparse
import json
import sys

parser = argparse.ArgumentParser()
parser.add_argument('--input', required=True)
parser.add_argument('--output', required=True)
args = parser.parse_args()

with open(args.input, 'r', encoding='utf-8') as f:
    data = json.load(f)

species_list = data.get('species', [])

mapped = []

# helper checks
def is_type_val(v):
    return isinstance(v, int) and 0 <= v <= 18

def is_catch(v):
    return isinstance(v, int) and 0 <= v <= 255

def is_small(v):
    return isinstance(v, int) and 0 <= v <= 500

for idx, entry in enumerate(species_list, start=1):
    # ensure entry is list of ints/strings
    if not isinstance(entry, list):
        continue
    # pad to length
    e = entry
    e_len = len(e)
    rec = {'id': idx}
    # base stats
    if e_len >= 6:
        rec['base'] = {
            'hp': int(e[0]) if isinstance(e[0], int) else None,
            'atk': int(e[1]) if isinstance(e[1], int) else None,
            'def': int(e[2]) if isinstance(e[2], int) else None,
            'spd': int(e[3]) if isinstance(e[3], int) else None,
            'spatk': int(e[4]) if isinstance(e[4], int) else None,
            'spdef': int(e[5]) if isinstance(e[5], int) else None,
        }
    else:
        # fallback: fill what we can
        rec['base'] = {}
        for i, name in enumerate(['hp','atk','def','spd','spatk','spdef']):
            rec['base'][name] = int(e[i]) if i < e_len and isinstance(e[i], int) else None
    # remaining heuristics
    cursor = 6
    # types
    types = []
    if cursor < e_len and is_type_val(e[cursor]):
        types.append(int(e[cursor])); cursor += 1
        if cursor < e_len and is_type_val(e[cursor]):
            types.append(int(e[cursor])); cursor += 1
    if types:
        rec['types'] = types
    # catch rate
    if cursor < e_len and is_catch(e[cursor]):
        rec['catch_rate'] = int(e[cursor]); cursor += 1
    # exp yield
    if cursor < e_len and is_small(e[cursor]):
        rec['exp_yield'] = int(e[cursor]); cursor += 1
    # ev yield (heuristic: a small number)
    if cursor < e_len and is_small(e[cursor]):
        rec['ev_yield'] = int(e[cursor]); cursor += 1
    # possible held items (two entries sometimes)
    items = []
    for _ in range(2):
        if cursor < e_len and isinstance(e[cursor], int) and e[cursor] >= 0 and e[cursor] <= 65535:
            items.append(int(e[cursor])); cursor += 1
    if items:
        rec['items'] = items
    # gender ratio
    if cursor < e_len and isinstance(e[cursor], int) and 0 <= e[cursor] <= 255:
        rec['gender_ratio'] = int(e[cursor]); cursor += 1
    # egg cycles
    if cursor < e_len and isinstance(e[cursor], int) and 0 <= e[cursor] <= 255:
        rec['egg_cycles'] = int(e[cursor]); cursor += 1
    # friendship
    if cursor < e_len and isinstance(e[cursor], int) and 0 <= e[cursor] <= 255:
        rec['friendship'] = int(e[cursor]); cursor += 1
    # growth rate / egg groups / abilities - guess by remaining values
    # Collect any remaining small ints into 'extras'
    extras = []
    while cursor < e_len:
        if isinstance(e[cursor], int):
            extras.append(int(e[cursor]))
        else:
            extras.append(e[cursor])
        cursor += 1
    if extras:
        rec['extras'] = extras

    mapped.append(rec)

out = {'count': len(mapped), 'species': mapped}
with open(args.output, 'w', encoding='utf-8') as f:
    json.dump(out, f, indent=2)

print(f'Wrote {len(mapped)} mapped species to {args.output}')
