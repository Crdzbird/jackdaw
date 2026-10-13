part of 'session_record.dart';

/// A tool call began executing; its outcome is not known yet.
final class ToolStartedRecord extends SessionRecord {
  /// Records that the call [callId] started.
  const factory(String callId) = ToolStartedRecord._;

  const new _(this.callId) : super._();

  /// Identifier of the started call.
  final String callId;
}
