import 'package:jackdaw/src/agent/agent.dart';
import 'package:jackdaw/src/agent/agent_engine.dart';
import 'package:jackdaw/src/agent/agent_event.dart';
import 'package:jackdaw/src/agent/approval_decision.dart';
import 'package:jackdaw/src/agent/record_decisions.dart';
import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/session/session_record.dart';
import 'package:jackdaw/src/session/session_store.dart';

/// Long-lived, resumable sessions on an [Agent] with a store.
extension AgentSessions on Agent {
  /// Adds [message] to [sessionId] and continues it.
  Stream<AgentEvent> send(String sessionId, Message message) async* {
    await _sessions.append(sessionId, MessageRecord(message));
    yield* AgentEngine(this, _sessions, sessionId).run();
  }

  /// Continues [sessionId] from its journal, for example after a crash.
  Stream<AgentEvent> resume(String sessionId) async* {
    yield* AgentEngine(this, _sessions, sessionId).run();
  }

  /// Records [decisions] on calls of [sessionId] waiting for approval, then
  /// continues; any other call id fails the stream with [ArgumentError].
  Stream<AgentEvent> decide(
    String sessionId,
    Map<String, ApprovalDecision> decisions,
  ) async* {
    await recordDecisions(_sessions, sessionId, decisions);
    yield* AgentEngine(this, _sessions, sessionId).run();
  }

  SessionStore get _sessions =>
      store ?? (throw StateError('this agent has no session store'));
}
