import 'dart:convert';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_bench/src/bench_case.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

const _options = GenerationOptions(maxOutputTokens: 256);

/// Measures schema validity with the grammar against an instruction-only
/// baseline, judged strictly and leniently.
Future<Map<String, Object>> runStructuredBench(
  LocalModel model,
  List<BenchCase> cases,
) async {
  final watch = Stopwatch()..start();
  var constrained = 0;
  var strict = 0;
  var lenient = 0;
  for (final c in cases) {
    if (await _constrained(model, c)) constrained++;
    final text = await _baseline(model, c);
    if (_valid(c.schema, text)) strict++;
    if (_valid(c.schema, _between(text, '{', '}')) ||
        _valid(c.schema, _between(text, '[', ']'))) {
      lenient++;
    }
  }
  return {
    'cases': cases.length,
    'constrainedValid': constrained,
    'baselineStrictValid': strict,
    'baselineLenientValid': lenient,
    'seconds': watch.elapsed.inSeconds,
  };
}

Future<bool> _constrained(LocalModel model, BenchCase c) async {
  try {
    await generateJson(
      model,
      [Message.user(c.prompt)],
      c.schema,
      options: _options,
    );
    return true;
  } on StructuredOutputException {
    return false;
  }
}

Future<String> _baseline(LocalModel model, BenchCase c) async {
  final instruction =
      'Reply with JSON only, matching this JSON Schema: '
      '${jsonEncode(c.schema.toJson())}';
  final request = ModelRequest(
    messages: [Message.system(instruction), Message.user(c.prompt)],
    options: _options,
  );
  final events = await model.generate(request).toList();
  return events.whereType<TextDelta>().map((e) => e.text).join();
}

bool _valid(Schema schema, String text) {
  try {
    return schema.validate(jsonDecode(text)).isEmpty;
  } on FormatException {
    return false;
  }
}

String _between(String text, String open, String close) {
  final start = text.indexOf(open);
  final end = text.lastIndexOf(close);
  if (start < 0 || end <= start) return text;
  return text.substring(start, end + 1);
}
