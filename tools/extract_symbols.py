#!/usr/bin/env python3
"""
tools/extract_symbols.py
Simple symbol extractor that finds named array initializers from preprocessed headers and outputs JSON for gen1recomp.
Usage: extract_symbols.py input.i -o out.json

This is intentionally small and defensive: it looks for patterns like
    (const )?<type> <name>\[\] = { 0x.., ... };
and supports unsigned char/uint8_t/int arrays.

Not a full C parser; for robustness we require preprocessing (see preprocess_headers.sh).
"""

import re
import sys
import json
import argparse

array_re = re.compile(r"(?P<type>unsigned\s+char|const\s+unsigned\s+char|uint8_t|unsigned\s+short|uint16_t|int)\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*\[\s*\]\s*=\s*\{(?P<data>[^}]*)\}\s*;", re.S)
num_re = re.compile(r"0x[0-9A-Fa-f]+|\d+")


def parse_data(s):
    nums = num_re.findall(s)
    out = []
    for n in nums:
        if n.startswith('0x') or n.startswith('0X'):
            out.append(int(n,16))
        else:
            out.append(int(n))
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument('input')
    p.add_argument('-o','--output',default='symbols.json')
    args = p.parse_args()

    text = open(args.input,'r',encoding='utf-8',errors='ignore').read()

    symbols = []
    for m in array_re.finditer(text):
        name = m.group('name')
        typ = m.group('type')
        data = parse_data(m.group('data'))
        symbols.append({'name':name,'type':typ,'data':data})

    # JSON shaped for gen1recomp Lua runtime (example shape)
    out = {
        'gen1recomp': {
            'symbols': symbols
        }
    }

    with open(args.output,'w',encoding='utf-8') as f:
        json.dump(out,f,indent=2)
    print(f'Wrote {len(symbols)} symbols to {args.output}')

if __name__=='__main__':
    main()
