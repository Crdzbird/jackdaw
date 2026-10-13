import 'package:jackdaw/src/agent/agent.dart';
import 'package:jackdaw/src/agent/agent_event.dart';
import 'package:jackdaw/src/agent/agent_stop_reason.dart';
import 'package:jackdaw/src/agent/agent_turn.dart';
import 'package:jackdaw/src/agent/tool_round.dart';
import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/message/role.dart';
import 'package:jackdaw/src/model/model_request.dart';
import 'package:jackdaw/src/model/usage.dart';
import 'package:jackdaw/src/session/session_record.dart';
import 'package:jackdaw/src/session/session_state.dart';
import 'package:jackdaw/src/session/session_store.dart';
import 'package:jackdaw/src/tool/tool_box.dart';

/// Advances one session: model turns, tool rounds and the journal.
final class AgentEngine {
  /// Creates an engine for [sessionId] of [agent].
  factory(Agent agent, SessionStore store, String sessionId) = AgentEngine._;

  new _(this._agent, this._store, this._sessionId);

  final Agent _agent;
  final SessionStore _store;
  final String _sessionId;
  late final ToolBox _tools = ToolBox(_agent.tools);

  /// Continues the session until it answers, stops or needs approval.
  Stream<AgentEvent> run() async* {
    final state = SessionState(await _store.load(_sessionId));
    Future<void> record(SessionRecord r) async {
      await _store.append(_sessionId, r);
      state.apply(r);
    }

    var usage = const Usage();
    var steps = 0;
    while (true) {
      final calls = state.openCalls;
      if (calls.isNotEmpty) {
        final round = ToolRound(
          state: state,
          tools: _tools,
          policy: _agent.policy,
          record: record,
        );
        yield* round.resolve(calls);
        if (round.waiting) {
          yield _finish(state, usage, AgentStopReason.awaitingApproval);
          return;
        }
        final results = [for (final call in calls) state.results[call.id]!];
        await record(MessageRecord(Message(role: Role.tool, parts: results)));
        continue;
      }
      if (state.answered) {
        yield _finish(state, usage, AgentStopReason.completed);
        return;
      }
      if (steps >= _agent.maxSteps) {
        yield _finish(state, usage, AgentStopReason.stepLimit);
        return;
      }
      steps++;
      final turn = AgentTurn();
      yield* turn.drive(_agent.model.generate(_request(state.messages)));
      usage += turn.usage;
      await record(MessageRecord(turn.toMessage()));
    }
  }

  ModelRequest _request(List<Message> messages) => ModelRequest(
    messages: List.unmodifiable([
      if (_agent.instructions case final text?) Message.system(text),
      ...messages,
    ]),
    tools: _tools.specs,
    options: _agent.options,
  );

  AgentFinished _finish(
    SessionState state,
    Usage usage,
    AgentStopReason reason,
  ) => AgentFinished(
    messages: List.unmodifiable(state.messages),
    usage: usage,
    reason: reason,
  );
}
