EMERALD PORT

This document explains the initial import pipeline and loader I added to gen1recomp
so we can begin porting Pokemon Emerald content from the pokeemerald decompilation.

What I added
- tools/emerald_importer.py  : A conservative Python script that extracts #define constants
  and naive initializer blocks from selected pokeemerald headers and writes JSON.
- lua/emerald_loader.lua     : A small Lua loader that reads those JSON files at runtime
  (works in LÖVE if you have a JSON library such as dkjson available).

How to run (developer workflow)
1. Clone pokeemerald locally (if you haven't already):
     git clone https://github.com/alexf125/pokeemerald /path/to/pokeemerald

2. From gen1recomp root, run the importer to produce data files:
     python3 tools/emerald_importer.py --src /path/to/pokeemerald --out data/emerald

   Notes:
   - The importer is intentionally simple and heuristic-based. For reliable results
     preprocess headers with your C compiler (e.g. `gcc -E`) if you run into macro
     or include issues.
   - The script currently targets a small set of headers (see HEADER_MAP at the top of
     tools/emerald_importer.py). Add entries for additional headers as needed.

3. In your LÖVE project, use the loader to read the produced JSON:
     local emerald = require('emerald_loader')
     local species, err = emerald.load('data/emerald/species_info.json')

   Or load every JSON in the directory:
     local all, err = emerald.load_all('data/emerald')

Next steps I can implement for you (pick any):
- Improve parser robustness: run a C preprocessor step automatically, strip comments
  and macro wrappers more thoroughly, and extract named arrays by symbol.
- Create a deterministic mapping from pokeemerald data structures to gen1recomp Lua
  runtime structures (species -> mon_base data, pokedex text -> localized strings,
  moves -> move definitions, etc.).
- Add asset conversion (graphics / palettes / cries) using pokeemerald's extracted data
  and tools already present in that repo.
- Integrate the pipeline into gen1recomp's build (Makefile) so it becomes repeatable.

If you want me to continue, tell me which of the next steps you want me to take and
I'll implement the next code changes and wire them into the repo.
