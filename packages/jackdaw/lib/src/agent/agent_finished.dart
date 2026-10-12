part of 'agent_event.dart';

/// The last event of a run, carrying the full transcript.
final class AgentFinished extends AgentEvent {
  /// Creates the final event.
  const factory({
    required List<Message> messages,
    required Usage usage,
    required AgentStopReason reason,
  }) = AgentFinished._;

  const new _({
    required this.messages,
    required this.usage,
    required this.reason,
  }) : super._();

  /// Every message of the run, including the input history.
  final List<Message> messages;

  /// Tokens used across all model calls of the run.
  final Usage usage;

  /// Why the run ended.
  final AgentStopReason reason;

  /// Text of the final assistant message.
  String get text => messages.last.text;
}
