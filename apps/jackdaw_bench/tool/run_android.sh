#!/usr/bin/env bash
# Runs the on-device benchmarks on a connected Android phone.
# Usage: tool/run_android.sh <device-id> <model.gguf> [bench,list]
set -euo pipefail

device="$1"
model="$2"
benches="${3:-}"
package="dev.crdzbird.jackdaw_bench"
target="/data/user/0/$package/files/model.gguf"
apk="build/app/outputs/flutter-apk/app-profile.apk"

cd "$(dirname "$0")/.."
flutter build apk --profile --target-platform android-arm64 \
  --target=integration_test/bench_test.dart \
  --dart-define=JACKDAW_MODEL="$target" --dart-define=BENCH="$benches"
adb -s "$device" install -r "$apk"
if ! adb -s "$device" shell run-as "$package" test -f files/model.gguf; then
  adb -s "$device" push "$model" /data/local/tmp/jackdaw-model.gguf
  adb -s "$device" shell run-as "$package" sh -c "'mkdir -p files && chmod 700 files && cp /data/local/tmp/jackdaw-model.gguf files/model.gguf'"
  adb -s "$device" shell rm /data/local/tmp/jackdaw-model.gguf
fi
flutter drive -d "$device" --profile --keep-app-running \
  --use-application-binary="$apk" \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/bench_test.dart
