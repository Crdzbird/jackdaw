#!/usr/bin/env bash
# Claim C9: builds packages/jackdaw_native/tool/offline_check.dart into a
# standalone bundle and runs its agent loop (tools, retrieval over the
# native index, structured output) with networking disabled by the
# operating system.
# Usage: tool/check_offline.sh <model.gguf>
set -euo pipefail

model="$1"
out="$(mktemp -d)"
cd "$(dirname "$0")/../packages/jackdaw_native"
dart build cli -t tool/offline_check.dart -o "$out" >/dev/null
bin="$out/bundle/bin/offline_check"

case "$(uname)" in
  Darwin)
    sandbox-exec -p '(version 1)(allow default)(deny network*)' "$bin" "$model"
    ;;
  Linux)
    sudo unshare --net -- sudo -u "$(id -un)" "$bin" "$model"
    ;;
  *)
    echo "unsupported platform: $(uname)"
    exit 2
    ;;
esac
