import 'package:jackdaw/src/trace/recorded_span.dart';
import 'package:jackdaw/src/trace/trace_span.dart';
import 'package:jackdaw/src/trace/tracer.dart';

/// A [Tracer] that keeps finished spans in memory, for tests and tools.
final class RecordingTracer implements Tracer {
  /// Creates an empty recorder.
  factory() = RecordingTracer._;

  new _();

  /// Finished spans, in the order they ended.
  final List<RecordedSpan> spans = [];

  @override
  TraceSpan startSpan(
    String name, {
    Map<String, Object?> attributes = const {},
  }) => RecordedSpan(name, attributes, spans.add);
}
