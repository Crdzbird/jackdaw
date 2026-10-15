#!/usr/bin/env bash
# Copies a GGUF model into the demo app's private files on an Android
# device, once. The app must be installed; run the demo once first.
# Usage: tool/push_model.sh <device-id> <model.gguf>
set -euo pipefail

device="$1"
model="$2"
package="dev.crdzbird.jackdaw_bench"

if ! adb -s "$device" shell pm path "$package" >/dev/null 2>&1; then
  echo "The demo app is not installed on $device yet. Run it once, then"
  echo "run this task again to copy the model."
  exit 0
fi
if adb -s "$device" shell run-as "$package" test -f files/model.gguf; then
  echo "Model already on $device."
  exit 0
fi
adb -s "$device" push "$model" /data/local/tmp/jackdaw-model.gguf
adb -s "$device" shell run-as "$package" sh -c "'mkdir -p files && chmod 700 files && cp /data/local/tmp/jackdaw-model.gguf files/model.gguf && chmod 600 files/model.gguf'"
adb -s "$device" shell rm /data/local/tmp/jackdaw-model.gguf
echo "Model copied to $device."
