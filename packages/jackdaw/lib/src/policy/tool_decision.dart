part 'tool_allowed.dart';
part 'tool_denied.dart';
part 'tool_needs_approval.dart';

/// What a `ToolPolicy` decided about one tool call.
sealed class ToolDecision {
  const new _();

  /// The call may run.
  const factory allow() = ToolAllowed;

  /// The call must not run; [reason] is shown to the model.
  const factory deny(String reason) = ToolDenied;

  /// A person must approve the call first; [reason] is shown to them.
  const factory ask(String reason) = ToolNeedsApproval;
}
