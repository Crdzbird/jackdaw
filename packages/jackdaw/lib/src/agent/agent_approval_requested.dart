part of 'agent_event.dart';

/// A tool call waits for a person's approval; the run stops after this.
final class AgentApprovalRequested extends AgentEvent {
  /// Creates an event for [call], explained by [reason].
  const factory(ToolCallPart call, String reason) = AgentApprovalRequested._;

  const new _(this.call, this.reason) : super._();

  /// The call waiting for approval, with the exact arguments that will run.
  final ToolCallPart call;

  /// Why approval is needed.
  final String reason;
}
