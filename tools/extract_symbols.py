#!/usr/bin/env python3
"""
tools/extract_symbols.py - improved
Scans one or more preprocessed C files and extracts named array initializers and simple struct array initializers.
Usage:
  python3 tools/extract_symbols.py --inputs file1.i file2.i -o build/symbols.json
Options:
  --names name1 name2  # optional list of symbol names to extract; if omitted, extract all found

This improved extractor records:
  - name: symbol name
  - c_type: the C type as found
  - raw: raw initializer text
  - parsed: best-effort parsed list of numbers/strings/nested arrays

Limitations: still not a full C parser; requires preprocessing to resolve macros.
"""

import argparse
import re
import json
from typing import List

# Patterns to match array initializers; captures type, name, and the initializer contents.
ARRAY_RE = re.compile(r"(?P<type>(?:const\s+)?(?:struct\s+\w+|unsigned\s+char|unsigned\s+short|uint8_t|uint16_t|u8|u16|u32|int|unsigned))\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*\[.*?\]\s*=\s*\{", re.S)

# We'll search for occurrences of 'name = {' and extract balanced braces after the first '{'
NAME_ASSIGN_RE = re.compile(r"(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*\{", re.S)

NUM_RE = re.compile(r"0x[0-9A-Fa-f]+|\d+")
STR_RE = re.compile(r'"(.*?)"', re.S)


def find_arrays_in_text(text: str):
    results = []
    # Find type/name positions first for stronger matches
    for m in ARRAY_RE.finditer(text):
        start = m.end() - 1  # position of '{'
        name = m.group('name')
        ctype = m.group('type')
        # extract the balanced braces content
        depth = 0
        i = start
        end = None
        while i < len(text):
            if text[i] == '{':
                depth += 1
            elif text[i] == '}':
                depth -= 1
                if depth == 0:
                    end = i
                    break
            i += 1
        if end:
            raw = text[start+1:end]
            results.append({'name': name, 'type': ctype, 'raw': raw})
    # As a fallback, find assignments like 'gSomething = { ... };'
    for m in NAME_ASSIGN_RE.finditer(text):
        name = m.group('name')
        # avoid duplicates
        if any(r['name'] == name for r in results):
            continue
        start = m.end() - 1
        depth = 0
        i = start
        end = None
        while i < len(text):
            if text[i] == '{':
                depth += 1
            elif text[i] == '}':
                depth -= 1
                if depth == 0:
                    end = i
                    break
            i += 1
        if end:
            raw = text[start+1:end]
            results.append({'name': name, 'type': None, 'raw': raw})
    return results


def tokenize_c_values(block_text: str):
    # Similar to prior approach: split top-level comma-separated items and parse numbers/strings/nested braces
    items = []
    cur = ''
    i = 0
    n = len(block_text)
    while i < n:
        ch = block_text[i]
        if ch == '{':
            # find balanced
            depth = 1
            j = i + 1
            while j < n:
                if block_text[j] == '{': depth += 1
                elif block_text[j] == '}': depth -= 1; 
                if depth == 0: break
                j += 1
            inner = block_text[i+1:j]
            items.append(tokenize_c_values(inner))
            i = j + 1
            # skip comma/space
            while i < n and block_text[i] in ', \t\r\n': i += 1
            continue
        elif ch == '"':
            # string
            j = i+1
            s = ''
            while j < n:
                if block_text[j] == '"' and block_text[j-1] != '\\':
                    break
                s += block_text[j]
                j += 1
            items.append(s)
            i = j+1
            # skip comma/space
            while i < n and block_text[i] in ', \t\r\n': i += 1
            continue
        elif ch == ',':
            if cur.strip():
                items.append(cur.strip())
            cur = ''
            i += 1
            continue
        else:
            cur += ch
        i += 1
    if cur.strip():
        items.append(cur.strip())

    # convert items
    def conv(x):
        if isinstance(x, list):
            return [conv(e) for e in x]
        s = x.strip() if isinstance(x, str) else x
        if isinstance(s, str) and s.startswith('"') and s.endswith('"'):
            return s[1:-1]
        if isinstance(s, str):
            # remove casts
            s2 = re.sub(r'\([^)]+\)', '', s).strip()
            # strip trailing ULs
            s2 = re.sub(r'[uUlL]+$', '', s2)
            # try hex/dec
            if re.match(r'^0x[0-9A-Fa-f]+$', s2):
                return int(s2, 16)
            try:
                return int(s2)
            except Exception:
                return s
        return s
    return [conv(it) for it in items]


def process_inputs(inputs: List[str], names_filter=None):
    found = []
    for path in inputs:
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            text = f.read()
        arrays = find_arrays_in_text(text)
        for a in arrays:
            name = a['name']
            if names_filter and name not in names_filter:
                continue
            parsed = None
            try:
                parsed = tokenize_c_values(a['raw'])
            except Exception as e:
                parsed = None
            found.append({'name': name, 'c_type': a.get('type'), 'raw': a['raw'][:1000], 'parsed_sample': (parsed[:50] if parsed else None)})
    return found


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--inputs', nargs='+', required=True)
    p.add_argument('--names', nargs='*', help='Optional list of symbol names to extract')
    p.add_argument('-o','--output', default='build/symbols.json')
    args = p.parse_args()

    symbols = process_inputs(args.inputs, names_filter=(set(args.names) if args.names else None))
    out = {'gen1recomp': {'symbols': symbols}}
    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(out, f, indent=2)
    print(f'Wrote {len(symbols)} symbols to {args.output}')

if __name__=='__main__':
    main()
