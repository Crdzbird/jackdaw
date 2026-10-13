import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/message/role.dart';
import 'package:jackdaw/src/session/message_codec.dart';
import 'package:jackdaw/src/session/session_record.dart';

/// Encodes [record] as JSON-compatible data.
Map<String, Object?> recordToJson(SessionRecord record) => switch (record) {
  MessageRecord(:final message) => {
    'type': 'message',
    'message': messageToJson(message),
  },
  ToolStartedRecord(:final callId) => {'type': 'toolStarted', 'callId': callId},
  ToolResultRecord(:final result) => {
    'type': 'toolResult',
    'result': messageToJson(_wrap(result)),
  },
  ApprovalRequestedRecord(:final callId, :final reason) => {
    'type': 'approvalRequested',
    'callId': callId,
    'reason': reason,
  },
  ApprovalDecidedRecord(:final callId, :final granted, :final note) => {
    'type': 'approvalDecided',
    'callId': callId,
    'granted': granted,
    'note': note,
  },
};

/// Decodes a record written by [recordToJson].
SessionRecord recordFromJson(Map<String, Object?> json) =>
    switch (json['type']) {
      'message' => MessageRecord(
        messageFromJson(json['message']! as Map<String, Object?>),
      ),
      'toolStarted' => ToolStartedRecord(json['callId']! as String),
      'toolResult' => ToolResultRecord(
        messageFromJson(json['result']! as Map<String, Object?>).parts.single
            as ToolResultPart,
      ),
      'approvalRequested' => ApprovalRequestedRecord(
        json['callId']! as String,
        json['reason']! as String,
      ),
      _ => ApprovalDecidedRecord(
        json['callId']! as String,
        granted: json['granted']! as bool,
        note: json['note']! as String,
      ),
    };

Message _wrap(ToolResultPart result) =>
    Message(role: Role.tool, parts: [result]);
