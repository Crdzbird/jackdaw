import 'dart:convert';
import 'dart:io';

import 'package:jackdaw_bench/src/structured_bench.dart';
import 'package:jackdaw_bench/src/structured_cases.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

/// Runs the 200-case structured output benchmark on the desktop for the
/// GGUF files given as arguments. With `--cpu` the model runs on four CPU
/// threads and leaves the GPU and the other cores free.
Future<void> main(List<String> args) async {
  final cpu = args.contains('--cpu');
  for (final path in args.where((a) => !a.startsWith('--'))) {
    final model = await LocalModel.open(
      path,
      options: cpu
          ? const LocalModelOptions(
              gpuLayers: 0,
              session: NativeSessionOptions(threads: 4),
            )
          : const LocalModelOptions(),
    );
    final result = await runStructuredBench(model, structuredCases());
    stdout.writeln(jsonEncode({'model': model.id, 'cpu': cpu, ...result}));
    model.close();
  }
}
