import 'package:jackdaw/src/trace/redactor.dart';
import 'package:jackdaw/src/trace/trace_span.dart';

/// A span whose attributes and error pass through a [Redactor].
final class RedactingSpan implements TraceSpan {
  /// Redacts what reaches [inner].
  const factory(TraceSpan inner, Redactor redactor) = RedactingSpan._;

  const new _(this._inner, this._redactor);

  final TraceSpan _inner;
  final Redactor _redactor;

  @override
  void setAttribute(String key, Object? value) =>
      _inner.setAttribute(key, _redactor.redact(value));

  @override
  void end({Object? error}) =>
      _inner.end(error: error == null ? null : _redactor.redact('$error'));
}
