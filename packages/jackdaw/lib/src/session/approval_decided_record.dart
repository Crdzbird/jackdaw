part of 'session_record.dart';

/// A person approved or rejected a pending call.
final class ApprovalDecidedRecord extends SessionRecord {
  /// Records the decision on [callId].
  const factory(String callId, {required bool granted, String note}) =
      ApprovalDecidedRecord._;

  const new _(this.callId, {required this.granted, this.note = ''}) : super._();

  /// Identifier of the decided call.
  final String callId;

  /// Whether the call may run.
  final bool granted;

  /// Optional explanation, shown to the model on rejection.
  final String note;
}
