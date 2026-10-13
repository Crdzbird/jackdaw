import 'dart:convert';
import 'dart:io';

import 'package:jackdaw_bench/src/structured_bench.dart';
import 'package:jackdaw_bench/src/structured_cases.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

/// Runs the 200-case structured output benchmark on the desktop for the
/// GGUF files given as arguments.
Future<void> main(List<String> paths) async {
  for (final path in paths) {
    final model = await LocalModel.open(path);
    final result = await runStructuredBench(model, structuredCases());
    stdout.writeln(jsonEncode({'model': model.id, ...result}));
    model.close();
  }
}
