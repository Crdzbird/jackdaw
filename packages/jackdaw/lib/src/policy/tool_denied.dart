part of 'tool_decision.dart';

/// The call must not run.
final class ToolDenied extends ToolDecision {
  /// Creates a denial explained by [reason].
  const factory(String reason) = ToolDenied._;

  const new _(this.reason) : super._();

  /// Why the call was denied; shown to the model.
  final String reason;
}
