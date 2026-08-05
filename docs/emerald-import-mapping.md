# Emerald import mapping — Phase 0

This document maps pokeemerald repository files (source) to the generated-data artifacts gen1recomp expects (target). It also records immediate notes, gaps, and next steps for the conversion skeleton.

IMPORTANT: this is an evidence-backed inventory produced from pokeemerald (https://github.com/alexf125/pokeemerald) and gen1recomp (branch feature/emerald-recomp). Use it as the single source of truth for the initial importer work.

---

## High-level targets (engine-side)

gen1recomp expects a versioned generated cache with two main families:

- assets/generated/   (PNG tilesheets, spritesheets, palettes, audio programs)
- data/generated/     (Lua modules: pokemon, moves, items, maps, tilesets, encounters, etc.)

The importer must produce those files in the same shape as the existing gen1recomp LuaWriter/ImageWriter produce for Gen1 ROMs.

## pokeemerald source → gen1recomp targets (important files)

Note: paths are relative to the pokeemerald repo root.

- Pokemon / species / growth / stats
  - pokeemerald: src/data/pokemon/*, src/data/pokemon_graphics/, src/data/pokemon/ (many headers like "pokemon.h", species definitions, animation tables)
  - gen1recomp target: data/generated/pokemon.lua (table keyed by species id / name), assets/generated/sprites (front/back PNGs), data/generated/growth.lua / stats.lua
  - Notes: species base stats, types, catch rate, base experience, learnsets are present in pokeemerald's src/data/pokemon headers and accompanying JSON exports under src/data/pokemon in the decomp.

- Moves
  - pokeemerald: src/data/battle_moves.h (and related data files under src/data)
  - gen1recomp target: data/generated/moves.lua (move metadata, power, accuracy, pp, effect id, flags)

- Items
  - pokeemerald: src/data/items.h, src/data/item_icon_table.h
  - gen1recomp target: data/generated/items.lua, assets/generated/item_icons.png

- Maps / tilesets / metatiles / metatile behaviors
  - pokeemerald: data/maps.s, data/maps/ (binary map blobs), src/data/tilesets/, src/tilesets.c, src/metatile_behavior.c
  - gen1recomp target: assets/generated/tilesheets/*.png, data/generated/maps/*.lua (map metadata + collisions), data/generated/tilesets.lua
  - Notes: Emerald uses metatile attribute flags, palette banks, and has explicit metatile behavior code (src/metatile_behavior.c). The converter must extract metatile attributes and preserve behavior semantics.

- Scripts / event opcode table
  - pokeemerald: data/event_scripts.s, data/script_cmd_table.inc, src/script.c, src/scrcmd.c
  - gen1recomp target: data/generated/scripts/*.lua or an engine-side interpreter that maps opcodes → Commands
  - Notes: Two approaches: translate script bytecode into gen1recomp's script commands, or embed a small opcode interpreter that executes original opcodes against engine APIs. For parity, the interpreter approach is safer initially.

- Wild encounters
  - pokeemerald: src/data/wild_encounters.json (and data/wild_encounters.*)
  - gen1recomp target: data/generated/encounters.lua

- Battle data, AI, animations, and scripts
  - pokeemerald: data/battle_scripts_1.s, data/battle_anim_scripts.s, src/battle_*.c and data/battle_ai_scripts.s
  - gen1recomp target: src/battle/ ruleset implementation (Damage.lua equivalents), data/generated/battle_script assets if needed
  - Notes: The battle logic will be ported to Lua using pokeemerald's C as the authoritative reference. RNG & random.c are critical for parity.

- RNG
  - pokeemerald: src/random.c
  - gen1recomp target: src/core/RNG.lua (or extending existing RNG implementation) to match the GBA PRNG behavior exactly (including seed & advancement rules)

- Sound / music
  - pokeemerald: data/sound_data.s, tools in src/m4a.c, m4a tables
  - gen1recomp target: assets/generated/audio programs or synthesized replacements
  - Notes: Sound conversion is non-trivial; initial MVP can use placeholders or synthesized chip-style music.

## Files / locations I inspected (evidence)

- pokeemerald/data/: battle_scripts_1.s, battle_anim_scripts.s, event_scripts.s, maps.s, map_events.s, tilesets/
- pokeemerald/src/: random.c, metatile_behavior.c, tilesets.c, tileset_anims.c, script.c, scrcmd.c, battle_*.c, src/data/ headers and JSON exports under src/data/
- gen1recomp/src/import/: RomImporter.lua, RomExtractor.lua, LuaWriter.lua, ImageWriter.lua — these show the expected generated artifact shapes and writer conventions.

(See full repo scan for complete listing).

## Immediate conversion gaps & decisions

1. Scripts: Emerald's opcode set is larger and engine-specific. Two options:
   - Translate to gen1recomp's script Commands (non-trivial, may change semantics)
   - Implement an opcode interpreter in Lua that uses gen1recomp engine hooks (recommended for parity)

2. Graphics: pokeemerald contains tile/graphics sources in data/ and src/data/graphics; but many are binary blobs (s, gba) and the decomp also includes helpers and JSON exports. The ImageWriter can take raw tiles + palette arrays and produce PNGs; conversion tools will likely need decompress (LZ77) and TI/texture assembly.

3. Audio: complex; defer full conversion for MVP. Use synthesized placeholders and plan separate audio conversion phase.

## Phase 0 deliverables (this commit)

- mapping document (this file)
- initial conversion skeleton (tools/emerald-convert/convert_pokeemerald.py)
- README for conversion tools (tools/emerald-convert/README.md)

## Next steps (Phase 0 -> Phase 1)

1. Run the conversion skeleton locally against a clone of pokeemerald. It must be given the pokeemerald path and an output path inside gen1recomp's data/generated and assets/generated.
2. Implement parsing for the highest-priority data first: species, moves, items, wild encounters, tilesets (one tileset & one map as a vertical slice).
3. Produce a vertical-slice sample (one town + route, 8–10 species, 10–15 moves) and a minimal battle ruleset port that validates RNG & damage formulas.

---

If you want, I can now commit the conversion skeleton on feature/emerald-recomp and open a PR with this mapping file and the skeleton script (small test harness). After you review, I will iterate on converters for species and moves next.
