#!/usr/bin/env python3
"""
tools/parse_moves.py

Prototype move extractor. Scans build/symbols.json for symbols that look like move tables
(e.g., names containing 'Move', 'gBattleMoves', 'gMoves') and writes a minimal
build/moves.json with an array of discovered move entries. Each move entry is a
best-effort mapping: id (index), name (if string present), and raw fields list.

Usage:
  python3 tools/parse_moves.py --symbols build/symbols.json --out build/moves.json

This is heuristic and intended to produce data sufficient for a minimal battle demo.
"""
import argparse
import json
import sys
import os
import re

p = argparse.ArgumentParser()
p.add_argument('--symbols', required=True)
p.add_argument('--out', required=True)
args = p.parse_args()

with open(args.symbols, 'r', encoding='utf-8') as f:
    data = json.load(f)

symbols = data.get('gen1recomp', {}).get('symbols', [])

candidates = []
for s in symbols:
    name = s.get('name','')
    if re.search(r'\bMove\b|gMoves|gBattleMoves|gStatChanges', name, re.IGNORECASE):
        parsed = s.get('parsed_sample')
        if parsed is None:
            continue
        # flatten nested lists into list of entries if possible
        if isinstance(parsed, list) and len(parsed)>0 and isinstance(parsed[0], list):
            entries = parsed
        else:
            # fallback: try splitting raw
            raw = s.get('raw','')
            entries = []
            # naive: each line with braces -> collect numbers/strings
            parts = re.split(r'\},\s*\{', raw)
            for ptext in parts:
                nums = re.findall(r'0x[0-9A-Fa-f]+|\d+|"[^"]*"', ptext)
                entry = []
                for n in nums:
                    if n.startswith('"'):
                        entry.append(n[1:-1])
                    elif n.startswith('0x'):
                        entry.append(int(n,16))
                    else:
                        entry.append(int(n))
                if entry:
                    entries.append(entry)
        if entries:
            candidates.append({'name': name, 'entries': entries})

moves_out = []
# pick first candidate and map entries to id/name/raw
if candidates:
    cand = candidates[0]
    for i, e in enumerate(cand['entries']):
        move = {'id': i+1}
        # try to extract a name if present as string in fields
        name = None
        for item in e:
            if isinstance(item, str):
                name = item
                break
        if name:
            move['name'] = name
        move['raw'] = e
        moves_out.append(move)

# write out
os.makedirs(os.path.dirname(args.out) or '.', exist_ok=True)
with open(args.out, 'w', encoding='utf-8') as f:
    json.dump({'moves': moves_out, 'source': (candidates[0]['name'] if candidates else None)}, f, indent=2)

print(f'Wrote {len(moves_out)} moves to {args.out} (source: {candidates[0]["name"] if candidates else None})')
