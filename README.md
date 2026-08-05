# README.md
This branch adds an Emerald conversion scaffold and a minimal LÖVE prototype to gen1recomp (branch: feature/emerald-recomp).

What I added:
- tools/emerald_convert.lua — conservative extractor to turn pokeemerald C data into Lua tables (extend for full conversion)
- love/ — a small LÖVE prototype (main.lua + battle.lua) that demonstrates loading species, playing cries, and drawing simple animated placeholders
- data/emerald_species_sample.lua — sample data for Treecko/Torchic/Mudkip for quick demo
- audio/README.md and animations/README.md — instructions / placeholders for extracting real audio & animations from pokeemerald

Your preferences applied:
- True parity: the converter is written so you can extract the authoritative tables from pokeemerald; next step is to run and extend it against the full repo to produce complete data files.
- Audio: the prototype supports playing converted cries/music; audio extraction instructions are included.
- Animations: animation extraction/integration guidance and hooks are included in the LÖVE code.

Next steps I can take automatically:
- Run the converter against your pokeemerald checkout (if you provide its path on the server or allow me to run it here) to generate full data/*.lua outputs.
- Add asset conversion scripts (sprites -> PNG, palettes) and run them to create assets/starters/*.png and audio files.
- Expand the LÖVE prototype into a fuller battle demo with trainer/wild battles and full animation scripts.

If you want me to proceed and run the converter here, reply with one of:
- "Run conversion now" — and provide the path or allow me to fetch the pokeemerald repo into the workspace.
- "Make assets" — I will try to extract/convert sprites and audio (may require additional binaries/tools).

If you'd rather proceed in pieces, tell me which step to run next and I will execute it.
