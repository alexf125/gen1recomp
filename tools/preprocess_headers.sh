#!/bin/sh
# tools/preprocess_headers.sh
# Preprocess C headers using gcc/clang -E. Usage: preprocess_headers.sh input.h > output.i

CC=${CC:-gcc}
if ! command -v "$CC" >/dev/null 2>&1; then
  echo "Error: $CC not found. Install gcc or set CC to clang." >&2
  exit 1
fi

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <header1.h> [header2.h ...]" >&2
  exit 2
fi

for f in "$@"; do
  echo "// Preprocessed: $f"
  "$CC" -E -P -undef -x c-header "$f" || exit $?
done
