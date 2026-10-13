#!/usr/bin/env bash
# Fails unless the lcov report given as the first argument covers every line,
# ignoring generated *.g.dart files. An optional second argument is a regular
# expression; only source files whose path matches it are checked, which
# browser coverage needs because it reports every loaded package.
set -euo pipefail

report="$1"
filter="${2:-.}"
awk -F: -v filter="$filter" '
  /^SF:/ { file = substr($0, 4); skip = (file ~ /\.g\.dart$/) || (file !~ filter) }
  skip { next }
  /^DA:/ { split($2, hit, ","); if (hit[2] == 0) print file ": line " hit[1] " not covered" }
  /^LF:/ { found += $2 }
  /^LH:/ { covered += $2 }
  END {
    printf "coverage: %d/%d lines\n", covered, found
    if (found == 0 || covered != found) exit 1
  }
' "$report"
