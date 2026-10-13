import 'package:jackdaw/jackdaw.dart';

/// What a journal says about the state of its session.
String journalSummary(List<SessionRecord> records) {
  final calls = <String>{};
  final results = <String>{};
  final asked = <String>{};
  final decided = <String>{};
  Message? last;
  for (final record in records) {
    switch (record) {
      case MessageRecord(:final message):
        last = message;
        calls.addAll(message.parts.whereType<ToolCallPart>().map((c) => c.id));
      case ToolResultRecord(:final result):
        results.add(result.callId);
      case ApprovalRequestedRecord(:final callId):
        asked.add(callId);
      case ApprovalDecidedRecord(:final callId):
        decided.add(callId);
      case ToolStartedRecord():
        break;
    }
  }
  final waiting = asked.difference(decided).difference(results);
  final open = calls.difference(results).difference(waiting);
  final state = switch (last?.role) {
    _ when waiting.isNotEmpty =>
      'waiting for approval of ${waiting.join(', ')}',
    _ when open.isNotEmpty => 'tool calls not finished: ${open.join(', ')}',
    Role.assistant => 'answered',
    null => 'empty',
    _ => 'waiting for the model',
  };
  return '${records.length} records, ${calls.length} tool calls; $state';
}
