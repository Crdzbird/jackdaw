import 'dart:convert';
import 'dart:io';

import 'package:jackdaw_bench/src/tool_bench.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

/// Runs the tool-calling benchmark on the desktop for the GGUF files given
/// as arguments.
Future<void> main(List<String> paths) async {
  for (final path in paths) {
    final model = await LocalModel.open(path);
    stdout.writeln(jsonEncode(await runToolBench(model)));
    model.close();
  }
}
