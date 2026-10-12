part of 'agent_event.dart';

/// The model produced a block of reasoning.
final class AgentReasoning extends AgentEvent {
  /// Creates an event carrying [part].
  const factory(ReasoningPart part) = AgentReasoning._;

  const new _(this.part) : super._();

  /// The reasoning.
  final ReasoningPart part;
}
