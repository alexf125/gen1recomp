# Makefile for gen1recomp (adds import-assets and run targets)
.PHONY: import-assets love-run

import-assets:
	@echo "Running import-assets pipeline (requires python3, gcc/clang, Pillow)"
	./scripts/import-assets.sh /path/to/pokeemerald
	@echo "Import finished. Assets in build/"

love-run:
	@echo "Run the LÖVE app in the 'love' folder: love ."
	@echo "Or run: love love/"
