import 'dart:math';
import 'dart:typed_data';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_bench/src/percentile.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

/// Claim C7: recall@10 against exact search, query latency and open time
/// for [count] vectors of [dims] components, saved under [directory].
///
/// [clustered] draws vectors around a thousand centres, which resembles
/// real embeddings; otherwise vectors are uniform noise, the hardest case
/// for quantized scores because neighbours are barely closer than the rest.
Future<Map<String, Object>> runVectorBench(
  String directory, {
  int count = 100000,
  int dims = 384,
  bool clustered = true,
  int recallQueries = 50,
  int timedQueries = 500,
}) async {
  final random = Random(42);
  Float32List noise(double scale) => Float32List.fromList([
    for (var i = 0; i < dims; i++) (random.nextDouble() * 2 - 1) * scale,
  ]);
  final centres = [for (var i = 0; i < 1000; i++) noise(1)];
  Float32List sample() {
    if (!clustered) return noise(1);
    final centre = centres[random.nextInt(centres.length)];
    final offset = noise(0.35);
    return Float32List.fromList([
      for (var i = 0; i < dims; i++) centre[i] + offset[i],
    ]);
  }

  final vectors = {for (var i = 0; i < count; i++) 'doc-$i': sample()};
  final index = NativeVectorIndex(dims);
  final addWatch = Stopwatch()..start();
  await index.add(vectors);
  final addMs = addWatch.elapsedMilliseconds;
  final exact = FlatVectorIndex(dims);
  await exact.add(vectors);
  final queries = [for (var i = 0; i < timedQueries; i++) sample()];
  var found = 0;
  for (final query in queries.take(recallQueries)) {
    final want = {for (final m in await exact.search(query)) m.id};
    found += (await index.search(query))
        .where((m) => want.contains(m.id))
        .length;
  }
  final latencies = <int>[];
  for (final query in queries) {
    final watch = Stopwatch()..start();
    await index.search(query);
    latencies.add(watch.elapsedMicroseconds);
  }
  final path = '$directory/c7.index';
  await saveIndex(index, path);
  index.dispose();
  final openWatch = Stopwatch()..start();
  final reopened = await openIndex(path);
  final openMs = openWatch.elapsedMilliseconds;
  final check = await reopened.search(queries.first, k: 1);
  reopened.dispose();
  return {
    'vectors': count,
    'dims': dims,
    'clustered': clustered,
    'recall_at_10': found / (recallQueries * 10),
    'query_p50_ms': percentileMs(latencies, 0.5),
    'query_p95_ms': percentileMs(latencies, 0.95),
    'add_ms': addMs,
    'open_ms': openMs,
    'reopened_ok': check.isNotEmpty,
  };
}
