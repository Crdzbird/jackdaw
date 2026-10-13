import 'package:jackdaw/src/agent/agent_event.dart';
import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/policy/tool_decision.dart';
import 'package:jackdaw/src/policy/tool_policy.dart';
import 'package:jackdaw/src/session/session_record.dart';
import 'package:jackdaw/src/session/session_state.dart';
import 'package:jackdaw/src/tool/tool.dart';
import 'package:jackdaw/src/tool/tool_box.dart';

/// Resolves the open tool calls of one assistant message.
///
/// Every outcome is journalled before it is reported, so
/// the round can resume after an interruption without repeating finished
/// calls or silently re-running calls that may already have had effects.
final class ToolRound {
  /// Creates a round over [state], the session being advanced.
  factory({
    required SessionState state,
    required ToolBox tools,
    required ToolPolicy policy,
    required Future<void> Function(SessionRecord record) record,
  }) = ToolRound._;

  new _({
    required this._state,
    required this._tools,
    required this._policy,
    required this._record,
  });

  final SessionState _state;
  final ToolBox _tools;
  final ToolPolicy _policy;
  final Future<void> Function(SessionRecord record) _record;

  /// Whether some call still waits for a person.
  bool waiting = false;

  /// Resolves [calls], running the allowed ones concurrently.
  Stream<AgentEvent> resolve(List<ToolCallPart> calls) async* {
    final allowed = <(ToolCallPart, Tool<Object?>)>[];
    for (final call in calls.where((c) => !_state.results.containsKey(c.id))) {
      final tool = _tools[call.name];
      final decision = await _decide(call, tool);
      switch (decision) {
        case null:
          waiting = true;
        case ToolAllowed():
          allowed.add((call, tool!));
        case ToolDenied(:final reason):
          yield await _fail(call, reason);
        case ToolNeedsApproval(:final reason):
          waiting = true;
          await _record(ApprovalRequestedRecord(call.id, reason));
          yield AgentApprovalRequested(call, reason);
      }
    }
    for (final (call, _) in allowed) {
      await _record(ToolStartedRecord(call.id));
    }
    final results = await Future.wait([
      for (final (call, tool) in allowed) _tools.invoke(tool, call),
    ]);
    for (final result in results) {
      await _record(ToolResultRecord(result));
      yield AgentToolResult(result);
    }
  }

  Future<ToolDecision?> _decide(ToolCallPart call, Tool<Object?>? tool) async {
    if (tool == null) return ToolDecision.deny('unknown tool ${call.name}');
    if (_state.started.contains(call.id) && !tool.idempotent) {
      return const ToolDecision.deny(
        'interrupted before finishing; the outcome is unknown and the call '
        'was not repeated',
      );
    }
    if (_state.decisions[call.id] case final decided?) {
      return decided.granted
          ? const ToolDecision.allow()
          : ToolDecision.deny('rejected: ${decided.note}');
    }
    if (_state.requested.containsKey(call.id)) return null;
    return await _policy.decide(call, tool);
  }

  Future<AgentToolResult> _fail(ToolCallPart call, String reason) async {
    final result = ToolResultPart(
      callId: call.id,
      name: call.name,
      output: {'error': reason},
      isError: true,
    );
    await _record(ToolResultRecord(result));
    return AgentToolResult(result);
  }
}
