#!/usr/bin/env python3
"""
tools/generate_player_sprite.py

Generate a small placeholder player sprite (16x16) into the build/assets directory.
Usage: python3 tools/generate_player_sprite.py build/assets/player.png
"""
from PIL import Image, ImageDraw
import sys, os

out = sys.argv[1] if len(sys.argv)>1 else 'build/assets/player.png'
os.makedirs(os.path.dirname(out), exist_ok=True)
W = H = 16
img = Image.new('RGBA', (W,H), (0,0,0,0))
d = ImageDraw.Draw(img)
# simple sprite: yellow circle with brown outline
d.ellipse((2,2,W-3,H-3), fill=(255,200,50,255), outline=(100,50,0,255))
# eyes
d.rectangle((5,6,6,7), fill=(0,0,0,255))
d.rectangle((9,6,10,7), fill=(0,0,0,255))
img.save(out)
print('Wrote player sprite:', out)
