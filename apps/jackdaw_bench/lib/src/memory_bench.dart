import 'dart:io';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

/// Loads, uses and frees the model [cycles] times and tracks resident
/// memory, to show that nothing accumulates.
Future<Map<String, Object>> runMemoryBench(
  String path, {
  int cycles = 100,
}) async {
  await _cycle(path);
  final baseline = ProcessInfo.currentRss;
  final samples = <int>[];
  for (var i = 1; i <= cycles; i++) {
    await _cycle(path);
    if (i % 10 == 0) samples.add(ProcessInfo.currentRss);
  }
  return {
    'cycles': cycles,
    'baselineMb': _mb(baseline),
    'finalMb': _mb(samples.last),
    'growthPercent': (samples.last - baseline) * 100 / baseline,
    'samplesMb': samples.map(_mb).toList(),
  };
}

Future<void> _cycle(String path) async {
  final model = await LocalModel.open(
    path,
    options: const LocalModelOptions(
      session: NativeSessionOptions(contextTokens: 1024),
    ),
  );
  await model
      .generate(
        ModelRequest(
          messages: [Message.user('Hi')],
          options: const GenerationOptions(maxOutputTokens: 4),
        ),
      )
      .drain<void>();
  model.close();
}

double _mb(int bytes) => bytes / (1024 * 1024);
