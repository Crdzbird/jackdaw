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
tool/push_model.sh "$device" "$model"
flutter drive -d "$device" --profile --keep-app-running \
  --use-application-binary="$apk" \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/bench_test.dart
