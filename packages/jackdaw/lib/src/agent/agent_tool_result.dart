part of 'agent_event.dart';

/// A tool finished and its result goes back to the model.
final class AgentToolResult extends AgentEvent {
  /// Creates an event carrying [result].
  const factory(ToolResultPart result) = AgentToolResult._;

  const new _(this.result) : super._();

  /// The tool's result.
  final ToolResultPart result;
}
