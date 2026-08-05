# audio/README.md
Instructions to extract music/cries from pokeemerald and convert to OGG for LÖVE

1) Build or locate the generated audio files in the pokeemerald repo build/data (the decomp includes audio build scripts).
2) Preferred pipeline: extract raw PCM or WAV, then encode to OGG Vorbis using ffmpeg:

   ffmpeg -i input.wav -ac 1 -ar 22050 -b:a 128k output.ogg

3) Put converted cries in gen1recomp/audio/cries/ and music tracks in gen1recomp/audio/music/.
4) For true parity, use the exact GBA mixes from pokeemerald's sound data; consult src/m4a_tables.c and src/m4a.c in pokeemerald for mapping.
