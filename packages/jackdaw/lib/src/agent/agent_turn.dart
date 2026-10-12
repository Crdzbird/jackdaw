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

  /// Tool calls requested during the turn.
  final List<ToolCallPart> calls = [];

  /// Usage reported by the model for the turn.
  Usage usage = const Usage();

  /// Forwards [events] as agent events and records what they contain.
  ///
  /// Built from stream operators rather than an `async*` loop so that
  /// cancelling the result cancels [events] at once on every compiler.
  Stream<AgentEvent> drive(Stream<ModelEvent> events) => events.expand(_record);

  Iterable<AgentEvent> _record(ModelEvent event) {
    switch (event) {
      case TextDelta(:final text):
        _text.write(text);
        return [AgentTextDelta(text)];
      case ToolCallEvent(:final call):
        calls.add(call);
        return [AgentToolCall(call)];
      case FinishEvent(usage: final reported):
        usage = reported;
        return const [];
    }
  }

  /// The assistant message produced by the turn.
  Message get message => Message(
    role: Role.assistant,
    parts: [if (_text.isNotEmpty) TextPart('$_text'), ...calls],
  );
}
