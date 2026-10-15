import 'package:jackdaw/src/agent/agent.dart';
import 'package:jackdaw/src/agent/agent_event.dart';
import 'package:jackdaw/src/agent/agent_request.dart';
import 'package:jackdaw/src/agent/agent_stop_reason.dart';
import 'package:jackdaw/src/agent/agent_turn.dart';
import 'package:jackdaw/src/agent/tool_round.dart';
import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/message/role.dart';
import 'package:jackdaw/src/model/usage.dart';
import 'package:jackdaw/src/session/session_record.dart';
import 'package:jackdaw/src/session/session_state.dart';
import 'package:jackdaw/src/session/session_store.dart';
import 'package:jackdaw/src/tool/tool_box.dart';
import 'package:jackdaw/src/trace/redact_by_default.dart';
import 'package:jackdaw/src/trace/trace_run.dart';
import 'package:jackdaw/src/trace/traced_model.dart';
import 'package:jackdaw/src/trace/tracer.dart';

/// Advances one session: model turns, tool rounds and the journal.
final class AgentEngine {
  /// Creates an engine for [sessionId] of [agent].
  factory(Agent agent, SessionStore store, String sessionId) = AgentEngine._;

  new _(this._agent, this._store, this._sessionId);

  final Agent _agent;
  final SessionStore _store;
  final String _sessionId;
  late final Tracer _tracer = redactByDefault(_agent.tracer);
  late final ToolBox _tools = ToolBox(
    _agent.tools,
    tracer: _tracer,
    content: _agent.traceContent,
    screen: _agent.screen,
  );
  late final TracedModel _model = TracedModel(
    _agent.model,
    _tracer,
    content: _agent.traceContent,
  );

  /// Continues the session until it answers, stops or needs approval.
  Stream<AgentEvent> run() => traceRun(_tracer, _sessionId, _loop());

  Stream<AgentEvent> _loop() async* {
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
      yield* turn.drive(
        _model.generate(agentRequest(_agent, _tools, state.messages)),
      );
      if (turn.failed) return;
      usage += turn.usage;
      await record(MessageRecord(turn.toMessage()));
    }
  }

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
