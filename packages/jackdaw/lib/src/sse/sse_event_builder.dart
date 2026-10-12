import 'package:jackdaw/src/sse/sse_event.dart';

/// Accumulates SSE lines into events, enforcing a size limit.
final class SseEventBuilder {
  /// Creates a builder that rejects events longer than [maxEventLength].
  factory(int maxEventLength) = SseEventBuilder._;

  new _(this._maxEventLength);

  final int _maxEventLength;
  final List<String> _data = [];
  int _length = 0;
  String _event = 'message';
  String? _id;

  /// Consumes one line and returns an event when [line] completes one.
  SseEvent? accept(String line) {
    if (line.isEmpty) return flush();
    if (line.startsWith(':')) return null;
    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    final raw = colon < 0 ? '' : line.substring(colon + 1);
    final value = raw.startsWith(' ') ? raw.substring(1) : raw;
    switch (field) {
      case 'data':
        _addData(value);
      case 'event':
        _event = value;
      case 'id':
        _id = value;
    }
    return null;
  }

  /// Returns the pending event, if it has data, and resets the builder.
  SseEvent? flush() {
    final event = _data.isEmpty
        ? null
        : SseEvent(data: _data.join('\n'), event: _event, id: _id);
    _data.clear();
    _length = 0;
    _event = 'message';
    return event;
  }

  void _addData(String value) {
    _length += value.length + 1;
    if (_length > _maxEventLength) {
      throw FormatException('SSE event longer than $_maxEventLength chars');
    }
    _data.add(value);
  }
}
