import 'package:jackdaw/src/trace/trace_span.dart';

/// A span kept in memory by a `RecordingTracer`.
final class RecordedSpan implements TraceSpan {
  /// Starts a span named [name] with [attributes].
  factory(
    String name,
    Map<String, Object?> attributes,
    void Function(RecordedSpan) onEnd,
  ) = RecordedSpan._;

  new _(this.name, Map<String, Object?> attributes, this._onEnd)
    : attributes = {...attributes};

  /// Span name, such as `jackdaw.tool`.
  final String name;

  /// Attributes set so far.
  final Map<String, Object?> attributes;

  /// The error the operation failed with, if any.
  Object? error;

  final void Function(RecordedSpan) _onEnd;
  final Stopwatch _watch = Stopwatch()..start();

  /// How long the span lasted; meaningful after it ended.
  Duration get duration => _watch.elapsed;

  @override
  void setAttribute(String key, Object? value) => attributes[key] = value;

  @override
  void end({Object? error}) {
    _watch.stop();
    this.error = error;
    _onEnd(this);
  }
}
