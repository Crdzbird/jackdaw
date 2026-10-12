#!/usr/bin/env bash
# Enforces the repository's Dart house rules on lib, test, example and tool code:
# at most 100 lines per file, at most one top-level type per file, no else
# branches, no inline comments other than doc comments, ASCII only.
set -euo pipefail

status=0
files=$(find packages -name '*.dart' -not -name '*.g.dart' -not -path '*/.dart_tool/*' -not -path '*/build/*')

for file in $files; do
  lines=$(wc -l < "$file")
  if [ "$lines" -gt 100 ]; then
    echo "$file: $lines lines (max 100)"
    status=1
  fi
  types=$(grep -cE '^(sealed |final |base |interface |abstract |mixin )*(class|enum|mixin|extension type) ' "$file" || true)
  if [ "$types" -gt 1 ]; then
    echo "$file: $types top-level types (max 1)"
    status=1
  fi
  if grep -nE '(^|[^A-Za-z_])else([^A-Za-z_]|$)' "$file"; then
    echo "$file: else branch"
    status=1
  fi
  if perl -ne 'print "$.: $_" if m{(^|[^/:])//(?!/)}' "$file" | grep .; then
    echo "$file: inline comment"
    status=1
  fi
  if perl -ne 'print "$.: $_" if /[^\x00-\x7F]/' "$file" | grep .; then
    echo "$file: non-ASCII character"
    status=1
  fi
done

exit $status
