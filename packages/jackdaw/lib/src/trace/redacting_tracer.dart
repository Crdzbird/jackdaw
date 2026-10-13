import 'package:jackdaw/src/trace/redacting_span.dart';
import 'package:jackdaw/src/trace/redactor.dart';
import 'package:jackdaw/src/trace/trace_span.dart';
import 'package:jackdaw/src/trace/tracer.dart';

/// Wraps a [Tracer] so every attribute and error passes through [redactor].
final class RedactingTracer implements Tracer {
  /// Redacts what reaches [inner].
  factory(Tracer inner, Redactor redactor) = RedactingTracer._;

  new _(this._inner, this.redactor);

  final Tracer _inner;

  /// Scrubs attribute values.
  final Redactor redactor;

  @override
  TraceSpan startSpan(
    String name, {
    Map<String, Object?> attributes = const {},
  }) {
    final clean = redactor.redact(attributes)! as Map<Object?, Object?>;
    return RedactingSpan(
      _inner.startSpan(name, attributes: clean.cast<String, Object?>()),
      redactor,
    );
  }
}
