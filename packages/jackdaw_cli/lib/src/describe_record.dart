import 'dart:convert';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_cli/src/clip.dart';

/// One timeline line for [record].
String describeRecord(SessionRecord record) => switch (record) {
  MessageRecord(:final message) => _message(message),
  ToolStartedRecord(:final callId) => 'tool started      $callId',
  ToolResultRecord(:final result) =>
    '${result.isError ? 'tool failed       ' : 'tool result       '}'
        '${result.callId} ${clip(jsonEncode(result.output), 80)}',
  ApprovalRequestedRecord(:final callId, :final reason) =>
    'approval asked    $callId: ${clip(reason, 80)}',
  ApprovalDecidedRecord(:final callId, :final granted, :final note) =>
    '${granted ? 'approved          ' : 'rejected          '}$callId'
        '${note.isEmpty ? '' : ': ${clip(note, 60)}'}',
};

String _message(Message message) {
  final calls = message.parts.whereType<ToolCallPart>().toList();
  final text = message.text.trim();
  final head = '${message.role.name}:'.padRight(18);
  return [
    if (text.isNotEmpty || calls.isEmpty) '$head${clip(text)}',
    for (final call in calls) _call(call),
  ].join('\n');
}

String _call(ToolCallPart call) =>
    '${'tool call:'.padRight(18)}${call.id} ${call.name} '
    '${clip(jsonEncode(call.arguments), 60)}';
