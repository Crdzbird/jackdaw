import 'package:jackdaw/src/trace/trace_span.dart';

/// A [TraceSpan] that ignores everything.
final class NoopSpan implements TraceSpan {
  /// Creates the no-op span.
  const factory() = NoopSpan._;

  const new _();

  @override
  void setAttribute(String key, Object? value) {}

  @override
  void end({Object? error}) {}
}
