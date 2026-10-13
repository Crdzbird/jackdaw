import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/message/role.dart';
import 'package:jackdaw/src/session/session_record.dart';

/// The state of a session, rebuilt by replaying its journal.
final class SessionState {
  /// Replays [records] in order.
  factory(List<SessionRecord> records) {
    final state = SessionState._();
    records.forEach(state.apply);
    return state;
  }

  new _();

  /// The transcript, oldest first.
  final List<Message> messages = [];

  /// Finished tool calls by call id.
  final Map<String, ToolResultPart> results = {};

  /// Calls that began executing.
  final Set<String> started = {};

  /// Calls that asked for approval, with the reason.
  final Map<String, String> requested = {};

  /// Approval decisions by call id.
  final Map<String, ApprovalDecidedRecord> decisions = {};

  /// Applies one [record].
  void apply(SessionRecord record) {
    switch (record) {
      case MessageRecord(:final message):
        messages.add(message);
      case ToolStartedRecord(:final callId):
        started.add(callId);
      case ToolResultRecord(:final result):
        results[result.callId] = result;
      case ApprovalRequestedRecord(:final callId, :final reason):
        requested[callId] = reason;
      case ApprovalDecidedRecord(:final callId):
        decisions[callId] = record;
    }
  }

  /// Tool calls of the last message, when it is an assistant message that
  /// asked for tools whose results are not in the transcript yet.
  List<ToolCallPart> get openCalls {
    if (messages.isEmpty || messages.last.role != Role.assistant) return [];
    return messages.last.toolCalls;
  }

  /// Whether the last message is a final assistant answer.
  bool get answered =>
      messages.isNotEmpty &&
      messages.last.role == Role.assistant &&
      messages.last.toolCalls.isEmpty;

  /// Calls waiting for a person's decision.
  List<String> get awaiting => [
    for (final id in requested.keys)
      if (!decisions.containsKey(id) && !results.containsKey(id)) id,
  ];
}
