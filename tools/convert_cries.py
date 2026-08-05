#!/usr/bin/env python3
"""
tools/convert_cries.py

Prototype converter for cry data. This script looks for arrays that might represent
cries and writes placeholder files (silent .wav with correct name) so the frontend
can reference them. A real implementation would decode the GBA's cry format or
use pokeemerald's audio extraction to produce WAV/OGG.

Usage:
  python3 tools/convert_cries.py --symbols build/symbols.json --out build/assets/cries
"""

import argparse
import json
import os
import wave

p = argparse.ArgumentParser()
p.add_argument('--symbols', required=True)
p.add_argument('--out', required=True)
args = p.parse_args()

with open(args.symbols, 'r', encoding='utf-8') as f:
    data = json.load(f)

symbols = data.get('gen1recomp', {}).get('symbols', [])

os.makedirs(args.out, exist_ok=True)

count = 0
for s in symbols:
    name = s.get('name')
    if not name:
        continue
    # heuristic: cry arrays often include 'Cry' or 'cry' in the name
    if 'cry' in name.lower():
        # write a 22050Hz 8-bit mono silent wav as placeholder
        outp = os.path.join(args.out, f'{name}.wav')
        with wave.open(outp, 'w') as w:
            w.setnchannels(1)
            w.setsampwidth(1)
            w.setframerate(22050)
            w.writeframes(b'\x80' * 22050 // 4)  # 0.25s of silence at mid-level for 8-bit
        count += 1
        print('Wrote placeholder cry:', outp)

print(f'Wrote {count} placeholder cries to {args.out}')
