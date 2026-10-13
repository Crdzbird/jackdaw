/// A person's answer to a pending tool call.
final class ApprovalDecision {
  /// Approves the call.
  const factory approve() = ApprovalDecision._approved;

  /// Rejects the call; [note] is shown to the model.
  const factory reject([String note]) = ApprovalDecision._rejected;

  const new _approved() : granted = true, note = '';

  const new _rejected([this.note = 'rejected by the user']) : granted = false;

  /// Whether the call may run.
  final bool granted;

  /// Explanation for a rejection.
  final String note;
}
