# animations/README.md
Guidance for animations extraction and integration

- pokeemerald stores frames / palettes in its graphics folders. To extract:
  - Use pokeemerald's gfx rules or tools (see graphics_file_rules.mk) or use a tile/bitmap extractor like grit or gbagfx.
  - Export frames as PNG sequences and place them in assets/animations/<name>/frame001.png ...

- In LÖVE, create simple sprite-sheet or frame animation loaders. The love/animation helper is intentionally left minimal; replace it with your project's system.

- For parity, extract frame timings from pokeemerald's battle_anim scripts (in data/). Those files describe animation sequences; you can adapt durations to match.
