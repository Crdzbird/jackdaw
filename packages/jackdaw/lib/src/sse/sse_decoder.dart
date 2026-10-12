import 'dart:async';
import 'dart:convert';

import 'package:jackdaw/src/sse/sse_event.dart';
import 'package:jackdaw/src/sse/sse_event_builder.dart';

/// Decodes a byte stream in the `text/event-stream` format into events.
///
/// Multi-byte characters split across chunks, CRLF line endings, comments
/// and multi-line data are handled. A final event without a trailing blank
/// line is still delivered. Events longer than [maxEventLength] characters
/// fail the stream with a [FormatException] instead of exhausting memory.
///
/// Built from stream operators rather than an `async*` loop so that
/// cancelling the result cancels the byte stream at once on every compiler.
final class SseDecoder extends StreamTransformerBase<List<int>, SseEvent> {
  /// Creates a decoder with the given size limit.
  const factory({int maxEventLength}) = SseDecoder._;

  const new _({this.maxEventLength = 1 << 20});

  /// Largest accepted event, in UTF-16 code units.
  final int maxEventLength;

  @override
  Stream<SseEvent> bind(Stream<List<int>> stream) {
    final builder = SseEventBuilder(maxEventLength);
    return stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .transform(
          StreamTransformer<String, SseEvent>.fromHandlers(
            handleData: (line, sink) => _emit(sink, () => builder.accept(line)),
            handleDone: (sink) {
              _emit(sink, builder.flush);
              sink.close();
            },
          ),
        );
  }

  static void _emit(EventSink<SseEvent> sink, SseEvent? Function() next) {
    try {
      final event = next();
      if (event != null) sink.add(event);
    } on FormatException catch (error, stackTrace) {
      sink.addError(error, stackTrace);
    }
  }
}
