import 'package:jackdaw/src/trace/noop_span.dart';
import 'package:jackdaw/src/trace/trace_span.dart';
import 'package:jackdaw/src/trace/tracer.dart';

/// A [Tracer] that records nothing; the default.
final class NoopTracer implements Tracer {
  /// Creates the no-op tracer.
  const factory() = NoopTracer._;

  const new _();

  @override
  TraceSpan startSpan(
    String name, {
    Map<String, Object?> attributes = const {},
  }) => const NoopSpan();
}
