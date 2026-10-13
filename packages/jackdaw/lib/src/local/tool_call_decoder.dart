import 'dart:async';
import 'dart:math';

import 'package:jackdaw/src/local/parse_tool_calls.dart';
import 'package:jackdaw/src/model/finish_reason.dart';
import 'package:jackdaw/src/model/model_event.dart';

/// Turns the output of a local model asked to use tools into model events.
///
/// Text that starts with `<` is a tool call: it is held back and, when the
/// model stops, parsed into `ToolCallEvent`s that end with the `toolCalls`
/// finish reason. Any other text streams through unchanged. Calls cut off
/// by the token limit, or that do not parse, fail the stream with
/// [FormatException] instead of reaching tools half written.
final class ToolCallDecoder
    extends StreamTransformerBase<ModelEvent, ModelEvent> {
  /// Creates a decoder for one model call.
  factory() = ToolCallDecoder._;

  new _();

  @override
  Stream<ModelEvent> bind(Stream<ModelEvent> stream) {
    final held = StringBuffer();
    bool? calling;
    final prefix = 'call_${Random().nextInt(0x7fffffff).toRadixString(36)}_';
    return stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (event, sink) {
          if (event case TextDelta(:final text) when calling != false) {
            held.write(text);
            final start = '$held'.trimLeft();
            if (start.isEmpty) return;
            calling = start.startsWith('<');
            if (calling!) return;
            sink.add(TextDelta('$held'));
            return;
          }
          if (event case FinishEvent(:final usage) when calling ?? false) {
            final calls = parseToolCalls('$held', prefix);
            if (calls == null || event.reason == FinishReason.length) {
              sink.addError(
                FormatException('incomplete tool call from the model', '$held'),
              );
              return;
            }
            calls.map(ToolCallEvent.new).forEach(sink.add);
            sink.add(FinishEvent(reason: FinishReason.toolCalls, usage: usage));
            return;
          }
          sink.add(event);
        },
      ),
    );
  }
}
