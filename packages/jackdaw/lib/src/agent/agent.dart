import 'package:jackdaw/src/agent/agent_engine.dart';
import 'package:jackdaw/src/agent/agent_event.dart';
import 'package:jackdaw/src/agent/approval_decision.dart';
import 'package:jackdaw/src/agent/record_decisions.dart';
import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/model/generation_options.dart';
import 'package:jackdaw/src/model/language_model.dart';
import 'package:jackdaw/src/policy/approval_policy.dart';
import 'package:jackdaw/src/policy/tool_policy.dart';
import 'package:jackdaw/src/session/in_memory_session_store.dart';
import 'package:jackdaw/src/session/session_record.dart';
import 'package:jackdaw/src/session/session_store.dart';
import 'package:jackdaw/src/tool/tool.dart';

/// Runs a model in a loop, executing the tools it asks for, until it
/// answers, needs approval, or has made [maxSteps] model calls. Each step is
/// journalled in [store], so a session survives the process being killed;
/// [policy] checks every tool call and [decide] answers pending approvals.
final class Agent {
  /// Creates an agent backed by [model].
  const factory({
    required LanguageModel model,
    List<Tool<Object?>> tools,
    String? instructions,
    int maxSteps,
    GenerationOptions options,
    ToolPolicy policy,
    SessionStore? store,
  }) = Agent._;

  const new _({
    required this.model,
    this.tools = const [],
    this.instructions,
    this.maxSteps = 8,
    this.options = const GenerationOptions(),
    this.policy = const ApprovalPolicy(),
    this.store,
  });

  /// The model that decides what to do.
  final LanguageModel model;

  /// Tools the model may call; tools not listed here never run.
  final List<Tool<Object?>> tools;

  /// System instructions sent before the transcript.
  final String? instructions;

  /// Maximum number of model calls in one invocation.
  final int maxSteps;

  /// Sampling settings for every model call.
  final GenerationOptions options;

  /// Decides whether each tool call runs, is refused, or needs approval.
  final ToolPolicy policy;

  /// Journal for [send], [resume] and [decide].
  final SessionStore? store;

  /// Runs once over [history] without keeping a session.
  Stream<AgentEvent> run(List<Message> history) async* {
    final scratch = InMemorySessionStore();
    for (final message in history) {
      await scratch.append('run', MessageRecord(message));
    }
    yield* AgentEngine(this, scratch, 'run').run();
  }

  /// Adds [message] to [sessionId] and continues it.
  Stream<AgentEvent> send(String sessionId, Message message) async* {
    await _store.append(sessionId, MessageRecord(message));
    yield* AgentEngine(this, _store, sessionId).run();
  }

  /// Continues [sessionId] from its journal, for example after a crash.
  Stream<AgentEvent> resume(String sessionId) async* {
    yield* AgentEngine(this, _store, sessionId).run();
  }

  /// Records [decisions] on calls of [sessionId] waiting for approval, then
  /// continues; any other call id fails the stream with [ArgumentError].
  Stream<AgentEvent> decide(
    String sessionId,
    Map<String, ApprovalDecision> decisions,
  ) async* {
    await recordDecisions(_store, sessionId, decisions);
    yield* AgentEngine(this, _store, sessionId).run();
  }

  /// Runs over [history] and returns only the final event.
  Future<AgentFinished> complete(List<Message> history) async {
    final events = await run(history).toList();
    return events.whereType<AgentFinished>().single;
  }

  SessionStore get _store =>
      store ?? (throw StateError('this agent has no session store'));
}
