part of 'agent_event.dart';

/// The model asked for a tool to run.
final class AgentToolCall extends AgentEvent {
  /// Creates an event carrying [call].
  const factory(ToolCallPart call) = AgentToolCall._;

  const new _(this.call) : super._();

  /// The requested call.
  final ToolCallPart call;
}
