import 'dart:convert';
import 'dart:io';

import 'package:jackdaw_bench/src/vector_bench.dart';

Future<void> main() async {
  final dir = await Directory.systemTemp.createTemp('jackdaw_c7');
  for (final clustered in [true, false]) {
    final result = await runVectorBench(dir.path, clustered: clustered);
    stdout.writeln(jsonEncode(result));
  }
  await dir.delete(recursive: true);
}
