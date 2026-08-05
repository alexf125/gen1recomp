#!/usr/bin/env python3
"""
tools/generate_moves_placeholder.py

If no moves are extracted, generate a small placeholder moves.json so the demo battle
has a few move names and simple damage values.
"""
import json, os, sys
out = sys.argv[1] if len(sys.argv)>1 else 'build/moves.json'
os.makedirs(os.path.dirname(out) or '.', exist_ok=True)
placeholder = {
  'moves': [
    {'id':1, 'name':'Tackle', 'power':40},
    {'id':2, 'name':'Scratch', 'power':40},
    {'id':3, 'name':'Ember', 'power':40}
  ]
}
with open(out, 'w', encoding='utf-8') as f:
    json.dump(placeholder, f, indent=2)
print('Wrote placeholder moves to', out)
