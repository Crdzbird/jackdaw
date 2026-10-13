import 'dart:convert';
import 'dart:io';

import 'package:jackdaw_cli/src/clip.dart';

/// `jackdaw trace <trace.jsonl>`: prints the spans written by a
/// `JsonlTracer`, with durations, token counts and errors, then totals.
Future<int> traceCommand(List<String> args, StringSink out) async {
  if (args.length != 1) {
    out.writeln('usage: jackdaw trace <trace.jsonl>');
    return 64;
  }
  final file = File(args.single);
  if (!file.existsSync()) {
    out.writeln('no such file: ${file.path}');
    return 66;
  }
  var input = 0;
  var output = 0;
  var failed = 0;
  var count = 0;
  for (final line in await file.readAsLines()) {
    final Object? span;
    try {
      span = jsonDecode(line);
    } on FormatException {
      continue;
    }
    if (span is! Map<String, Object?>) continue;
    count++;
    final attributes = span['attributes'] as Map? ?? const {};
    final ms = ((span['duration_us'] as num? ?? 0) / 1000).toStringAsFixed(1);
    final tokens = [
      if (attributes['gen_ai.usage.input_tokens'] case final int n) 'in=$n',
      if (attributes['gen_ai.usage.output_tokens'] case final int n) 'out=$n',
    ];
    if (span['name'] != 'invoke_agent') {
      input += attributes['gen_ai.usage.input_tokens'] as int? ?? 0;
      output += attributes['gen_ai.usage.output_tokens'] as int? ?? 0;
    }
    final error = span['error'];
    if (error != null) failed++;
    out.writeln(
      '${ms.padLeft(10)} ms  ${span['name']}'
      '${tokens.isEmpty ? '' : '  ${tokens.join(' ')}'}'
      '${error == null ? '' : '  error: ${clip('$error', 80)}'}',
    );
  }
  out.writeln(
    '$count spans, $failed failed, $input input and $output output tokens',
  );
  return 0;
}
