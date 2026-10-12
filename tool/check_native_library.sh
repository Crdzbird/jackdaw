#!/usr/bin/env bash
# Checks a built libjackdaw: only jackdaw_* symbols are exported and, for ELF
# files, every LOAD segment is aligned to 16 KB for Android.
# Usage: tool/check_native_library.sh <library> [llvm-bin-dir]
set -euo pipefail

library="$1"
bin="${2:-}"
nm="${bin:+$bin/}llvm-nm"
readelf="${bin:+$bin/}llvm-readelf"
command -v "$nm" >/dev/null || nm="nm"

if [[ "$library" == *.dylib ]]; then
  symbols=$("$nm" -gU "$library" | awk '{print $3}' | sed 's/^_//')
else
  symbols=$("$nm" -D --defined-only "$library" | awk '{print $3}')
fi
leaked=$(echo "$symbols" | grep -v '^jackdaw_' || true)
if [ -n "$leaked" ]; then
  echo "unexpected exported symbols:"
  echo "$leaked"
  exit 1
fi
echo "exports: $(echo "$symbols" | wc -l | tr -d ' ') jackdaw_* symbols"

if [[ "$library" == *.so ]]; then
  misaligned=$("$readelf" -lW "$library" | awk '$1 == "LOAD" && $NF != "0x4000"')
  if [ -n "$misaligned" ]; then
    echo "LOAD segments not 16 KB aligned:"
    echo "$misaligned"
    exit 1
  fi
  echo "alignment: all LOAD segments 16 KB"
fi
echo "size: $(wc -c < "$library" | tr -d ' ') bytes"
