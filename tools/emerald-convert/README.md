# Emerald conversion tools

This folder contains initial tooling to convert pokeemerald decompiled data into gen1recomp's generated-data format.

Goals for the skeleton in this branch:
- Provide a minimal, extensible Python interface that reads pokeemerald C/JSON data files and emits JSON/Lua-friendly intermediate files.
- Produce small vertical-slice output so the engine can load and run Emerald content for testing.

Requirements
- Python 3.10+
- pip install pyyaml (optional)

Usage (work in progress)

1. Clone pokeemerald somewhere local (e.g. ~/projects/pokeemerald)
2. From this repo (feature/emerald-recomp), run:

```sh
python3 tools/emerald-convert/convert_pokeemerald.py \
  --pokeemerald-path /path/to/pokeemerald \
  --out-data data/generated \
  --out-assets assets/generated
```

Notes
- This is an initial skeleton. It currently implements small parsers that extract array initializers and JSON exports where available. The script prints a plan and the files it would write. It does not overwrite existing gen1recomp generated data yet.
- Next changes will add explicit writers that match LuaWriter/ImageWriter's output format.

