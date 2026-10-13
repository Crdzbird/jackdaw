import 'dart:convert';
import 'dart:io';

import 'package:jackdaw/src/trace/recorded_span.dart';
import 'package:jackdaw/src/trace/trace_span.dart';
import 'package:jackdaw/src/trace/tracer.dart';

/// A [Tracer] that appends every finished span to [file] as one JSON line,
/// which `jackdaw trace` prints.
///
/// Each line holds the span name, its start time, its duration in
/// microseconds, its attributes and its error, if any. Values that are not
/// JSON are written as text. Agents redact common credential shapes before
/// spans reach a tracer; keep the file private all the same.
final class JsonlTracer implements Tracer {
  /// Appends spans to [file], creating it when missing.
  factory(File file) = JsonlTracer._;

  new _(this.file);

  /// The trace file.
  final File file;

  @override
  TraceSpan startSpan(
    String name, {
    Map<String, Object?> attributes = const {},
  }) {
    final started = DateTime.now().toUtc();
    return RecordedSpan(name, attributes, (span) {
      final line = jsonEncode({
        'name': span.name,
        'start': started.toIso8601String(),
        'duration_us': span.duration.inMicroseconds,
        'attributes': span.attributes,
        if (span.error != null) 'error': '${span.error}',
      }, toEncodable: (value) => '$value');
      file.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    });
  }
}
