#!/usr/bin/env python3
"""
tools/parse_species.py

Read the symbols.json produced by tools/extract_symbols.py and extract any symbol
whose name contains 'SPECIES' or 'Species' (heuristic). Emit build/species.json with
an array of parsed initializer samples ready for the LÖVE frontend.

Usage:
  python3 tools/parse_species.py --input build/symbols.json --output build/species.json

This is a conservative step that does not attempt to map struct fields; it simply
collects parsed initializer samples per species entry. Later we can add field
mapping once the struct layout is confirmed.
"""

import argparse
import json
import re
import sys

p = argparse.ArgumentParser()
p.add_argument('--input', required=True)
p.add_argument('--output', required=True)
args = p.parse_args()

with open(args.input, 'r', encoding='utf-8') as f:
    data = json.load(f)

symbols = data.get('gen1recomp', {}).get('symbols', [])

# Heuristic: pick symbols with names that include 'SPECIES' or 'Species' or 'gSpeciesInfo'
species_symbols = [s for s in symbols if re.search(r'species|Species|gSpeciesInfo', s['name'])]

if not species_symbols:
    print('No species-like symbols found in', args.input, file=sys.stderr)
    # Still write empty file for consistency
    with open(args.output, 'w', encoding='utf-8') as out:
        json.dump({'species': []}, out, indent=2)
    sys.exit(0)

# Some symbols may be whole arrays; pick the first matching symbol to be the species table
# If multiple, choose the one containing many entries (heuristic based on parsed_sample length)
best = None
best_len = 0
for s in species_symbols:
    parsed = s.get('parsed_sample')
    if isinstance(parsed, list) and len(parsed) > best_len:
        best = s
        best_len = len(parsed)

if not best:
    best = species_symbols[0]

# The parsed_sample may be a nested structure representing many species entries. If it's a list
# where each entry is itself a list/struct, use it. Otherwise, fall back to the raw text split.
species_list = []
parsed = best.get('parsed_sample')
if isinstance(parsed, list) and len(parsed) > 0 and isinstance(parsed[0], list):
    species_list = parsed
else:
    # Attempt a naive split: look for top-level nested braces in the raw text
    raw = best.get('raw', '')
    # split on '},' occurrences assuming each species ends with '},'
    parts = re.split(r'\},\s*\{', raw)
    for ptext in parts:
        # strip any braces
        ptext = ptext.strip()
        # reuse simple tokenizer from earlier: extract numbers and strings
        nums = re.findall(r'0x[0-9A-Fa-f]+|\d+|"[^"]*"', ptext)
        entry = []
        for n in nums:
            if n.startswith('"'):
                entry.append(n[1:-1])
            elif n.startswith('0x'):
                entry.append(int(n, 16))
            else:
                entry.append(int(n))
        species_list.append(entry)

out = {'symbol': best['name'], 'count': len(species_list), 'species': species_list}
with open(args.output, 'w', encoding='utf-8') as out_f:
    json.dump(out, out_f, indent=2)

print(f'Wrote {len(species_list)} species entries to {args.output} (symbol {best["name"]})')
