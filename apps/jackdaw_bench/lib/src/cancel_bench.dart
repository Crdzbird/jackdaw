import 'dart:async';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_bench/src/percentile.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

/// Measures the time from cancelling a stream to native decoding stopping.
Future<Map<String, Object>> runCancelBench(
  LocalModel model, {
  int runs = 20,
}) async {
  final latencies = <int>[];
  for (var i = 0; i < runs; i++) {
    latencies.add(await _once(model, i));
  }
  return {
    'runs': runs,
    'p50Ms': percentileMs(latencies, 0.5),
    'p95Ms': percentileMs(latencies, 0.95),
    'maxMs': percentileMs(latencies, 1),
  };
}

Future<int> _once(LocalModel model, int seed) async {
  final seen = Completer<void>();
  var count = 0;
  final subscription = model
      .generate(
        ModelRequest(
          messages: [Message.user('Write a very long story about a jackdaw.')],
          options: const GenerationOptions(temperature: 0.8),
        ),
      )
      .listen(
        (_) {
          count++;
          if (count == 3 && !seen.isCompleted) seen.complete();
        },
        onDone: () {
          if (!seen.isCompleted) seen.complete();
        },
      );
  await seen.future;
  final watch = Stopwatch()..start();
  await subscription.cancel();
  await model.idle;
  return watch.elapsedMicroseconds;
}
