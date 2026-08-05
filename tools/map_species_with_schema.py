#!/usr/bin/env python3
"""
tools/map_species_with_schema.py

Map species initializer arrays (from build/species.json) into a structured JSON
using a configurable schema (tools/species_schema.json). This is safer than
hard-coding field positions and allows iterative refinement.

Usage:
  python3 tools/map_species_with_schema.py --input build/species.json --schema tools/species_schema.json --output build/species_mapped.json

The schema is an ordered list of fields. Each field has:
  - name: field name in output
  - count: number of array items this field consumes (use -1 to collect remaining items into 'extras')
  - type: 'int'|'str'|'mixed'

If an entry has fewer values than expected, missing fields are set to null.
"""

import argparse
import json
import sys
import os

p = argparse.ArgumentParser()
p.add_argument('--input', required=True)
p.add_argument('--schema', required=True)
p.add_argument('--output', required=True)
args = p.parse_args()

with open(args.input, 'r', encoding='utf-8') as f:
    data = json.load(f)

with open(args.schema, 'r', encoding='utf-8') as f:
    schema = json.load(f)

entries = data.get('species', [])
fields = schema.get('fields', [])

mapped = []
for idx, entry in enumerate(entries, start=1):
    rec = {'id': idx}
    pos = 0
    for fld in fields:
        name = fld.get('name')
        count = fld.get('count', 1)
        ftype = fld.get('type', 'mixed')
        if count == -1:
            # collect remaining
            rem = entry[pos:]
            rec[name] = rem
            pos = len(entry)
            break
        vals = []
        for i in range(count):
            if pos < len(entry):
                vals.append(entry[pos])
            else:
                vals.append(None)
            pos += 1
        # simplify singletons
        if count == 1:
            rec[name] = vals[0]
        else:
            rec[name] = vals
    mapped.append(rec)

out = {'count': len(mapped), 'species': mapped}
with open(args.output, 'w', encoding='utf-8') as f:
    json.dump(out, f, indent=2)

print(f'Wrote {len(mapped)} mapped species to {args.output} using schema {args.schema}')
