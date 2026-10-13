import 'package:jackdaw/src/agent/agent.dart';
import 'package:jackdaw/src/agent/agent_engine.dart';
import 'package:jackdaw/src/agent/agent_event.dart';
import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/session/in_memory_session_store.dart';
import 'package:jackdaw/src/session/session_record.dart';

/// One-off runs of an [Agent] that keep no session.
extension AgentRuns on Agent {
  /// Runs once over [history] without keeping a session.
  Stream<AgentEvent> run(List<Message> history) async* {
    final scratch = InMemorySessionStore();
    for (final message in history) {
      await scratch.append('run', MessageRecord(message));
    }
    yield* AgentEngine(this, scratch, 'run').run();
  }

  /// Runs over [history] and returns only the final event.
  Future<AgentFinished> complete(List<Message> history) async =>
      (await run(history).toList()).whereType<AgentFinished>().single;
}
