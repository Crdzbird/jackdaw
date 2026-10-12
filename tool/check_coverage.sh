#!/usr/bin/env bash
# Fails unless the lcov report given as the first argument covers every line,
# ignoring generated *.g.dart files.
set -euo pipefail

report="$1"
awk -F: '
  /^SF:/ { file = $2; generated = (file ~ /\.g\.dart$/) }
  generated { next }
  /^DA:/ { split($2, hit, ","); if (hit[2] == 0) print file ": line " hit[1] " not covered" }
  /^LF:/ { found += $2 }
  /^LH:/ { covered += $2 }
  END {
    printf "coverage: %d/%d lines\n", covered, found
    if (found == 0 || covered != found) exit 1
  }
' "$report"
