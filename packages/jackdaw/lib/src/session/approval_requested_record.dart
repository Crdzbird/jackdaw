part of 'session_record.dart';

/// The policy asked a person to approve a call before it runs.
final class ApprovalRequestedRecord extends SessionRecord {
  /// Records the request for [callId].
  const factory(String callId, String reason) = ApprovalRequestedRecord._;

  const new _(this.callId, this.reason) : super._();

  /// Identifier of the call waiting for approval.
  final String callId;

  /// Why approval is needed.
  final String reason;
}
