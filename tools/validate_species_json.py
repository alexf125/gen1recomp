#!/usr/bin/env python3
"""
tools/validate_species_json.py

Simple validator for build/species_mapped.json. Checks:
 - file exists and parses
 - has 'count' and 'species'
 - for first N species, base stats are integers in 0..255

Usage:
  python3 tools/validate_species_json.py build/species_mapped.json
"""
import sys
import json

if len(sys.argv) < 2:
    print('Usage: validate_species_json.py <path>')
    sys.exit(2)

path = sys.argv[1]
try:
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
except Exception as e:
    print('Failed to read/parse', path, e)
    sys.exit(1)

count = data.get('count')
species = data.get('species')
if count is None or species is None:
    print('Invalid species mapped JSON: missing count or species')
    sys.exit(1)

print(f'Read species_mapped: count={count}, entries={len(species)}')
errors = 0
for i, s in enumerate(species[:10]):
    base = s.get('base', {})
    for fld in ['hp','atk','def','spd','spatk','spdef']:
        v = base.get(fld)
        if v is None:
            print(f'Entry {i+1}: missing base.{fld}')
            errors += 1
        else:
            if not isinstance(v, int) or v < 0 or v > 255:
                print(f'Entry {i+1}: base.{fld} out of range: {v}')
                errors += 1

if errors == 0:
    print('Validation passed for first 10 species (base stats OK)')
else:
    print(f'Validation found {errors} issues in first 10 species')
    sys.exit(2)
