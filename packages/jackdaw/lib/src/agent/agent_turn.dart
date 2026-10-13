import 'dart:async';

import 'package:jackdaw/src/agent/agent_event.dart';
import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/message/role.dart';
import 'package:jackdaw/src/model/model_event.dart';
import 'package:jackdaw/src/model/usage.dart';

/// Collects one model call into an assistant message while re-emitting
/// its events.
final class AgentTurn {
  /// Creates an empty turn.
  factory() = AgentTurn._;

  new _();

  final StringBuffer _text = StringBuffer();
  final List<Part> _parts = [];

  /// Tool calls requested during the turn.
  final List<ToolCallPart> calls = [];

  /// Usage reported by the model for the turn.
  Usage usage = const Usage();

  /// Whether the model call failed; a failed turn is not recorded.
  bool failed = false;

  /// Forwards [events] as agent events and records what they contain.
  ///
  /// Built from stream operators rather than an `async*` loop so that
  /// cancelling the result cancels [events] at once on every compiler.
  Stream<AgentEvent> drive(Stream<ModelEvent> events) => events.transform(
    StreamTransformer.fromHandlers(
      handleData: (event, sink) => _record(event).forEach(sink.add),
      handleError: (error, stack, sink) {
        failed = true;
        sink.addError(error, stack);
      },
    ),
  );

  Iterable<AgentEvent> _record(ModelEvent event) {
    switch (event) {
      case TextDelta(:final text):
        _text.write(text);
        return [AgentTextDelta(text)];
      case ReasoningEvent(:final part):
        _flushText();
        _parts.add(part);
        return [AgentReasoning(part)];
      case ToolCallEvent(:final call):
        _flushText();
        calls.add(call);
        _parts.add(call);
        return [AgentToolCall(call)];
      case FinishEvent(usage: final reported):
        usage = reported;
        return const [];
    }
  }

  /// The assistant message produced by the turn, with every part in the
  /// order the model produced it.
  Message toMessage() {
    _flushText();
    return Message(role: Role.assistant, parts: List.unmodifiable(_parts));
  }

  void _flushText() {
    if (_text.isEmpty) return;
    _parts.add(TextPart('$_text'));
    _text.clear();
  }
}
