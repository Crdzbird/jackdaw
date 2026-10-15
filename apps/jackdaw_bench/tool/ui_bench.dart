import 'dart:convert';
import 'dart:io';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_bench/src/ui_bench.dart';
import 'package:jackdaw_bench/src/ui_cases.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

/// Runs the 200-case UI benchmark of claim C13 on the desktop for the GGUF
/// files given as arguments. With `--cpu` the model runs on four CPU
/// threads, `--places=N` runs the cases of the first N places only, and
/// `--format=messages` asks for A2UI messages instead of a tree.
Future<void> main(List<String> args) async {
  final cpu = args.contains('--cpu');
  final places = int.tryParse(
    args.where((a) => a.startsWith('--places=')).firstOrNull?.substring(9) ??
        '',
  );
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
    final result = await runUiBench(
      model,
      uiCases(places: places ?? 10),
      format: args.contains('--format=messages')
          ? UiFormat.messages
          : UiFormat.tree,
    );
    stdout.writeln(jsonEncode({'model': model.id, 'cpu': cpu, ...result}));
    model.close();
  }
}
