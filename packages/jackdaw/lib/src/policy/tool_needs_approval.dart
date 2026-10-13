part of 'tool_decision.dart';

/// A person must approve the call before it runs.
final class ToolNeedsApproval extends ToolDecision {
  /// Creates a request for approval explained by [reason].
  const factory(String reason) = ToolNeedsApproval._;

  const new _(this.reason) : super._();

  /// Why approval is needed; shown to the person deciding.
  final String reason;
}
