import 'package:jackdaw/src/agent/agent_engine.dart';
import 'package:jackdaw/src/agent/agent_event.dart';
import 'package:jackdaw/src/context/context_budget.dart';
import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/model/generation_options.dart';
import 'package:jackdaw/src/model/language_model.dart';
import 'package:jackdaw/src/policy/approval_policy.dart';
import 'package:jackdaw/src/policy/tool_policy.dart';
import 'package:jackdaw/src/session/in_memory_session_store.dart';
import 'package:jackdaw/src/session/session_record.dart';
import 'package:jackdaw/src/session/session_store.dart';
import 'package:jackdaw/src/tool/tool.dart';
import 'package:jackdaw/src/trace/noop_tracer.dart';
import 'package:jackdaw/src/trace/tracer.dart';

/// Runs a model in a loop, executing the tools it asks for, until it
/// answers, needs approval, or has made [maxSteps] model calls. Each step is
/// journalled in [store], so a session survives the process being killed,
/// and [policy] checks every tool call. Sessions are driven through the
/// `AgentSessions` methods `send`, `resume` and `decide`.
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
    ContextBudget? budget,
    Tracer tracer,
    bool traceContent,
  }) = Agent._;

  const new _({
    required this.model,
    this.tools = const [],
    this.instructions,
    this.maxSteps = 8,
    this.options = const GenerationOptions(),
    this.policy = const ApprovalPolicy(),
    this.store,
    this.budget,
    this.tracer = const NoopTracer(),
    this.traceContent = false,
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

  /// Journal for sessions; required by `send`, `resume` and `decide`.
  final SessionStore? store;

  /// Limit for the transcript sent to the model; the journal keeps all.
  final ContextBudget? budget;

  /// Receives spans for the run, each model call and each tool call.
  /// Common credential shapes are always redacted from them.
  final Tracer tracer;

  /// Whether prompts, answers and tool data are attached to spans. Wrap
  /// [tracer] in a `RedactingTracer` with your secrets before turning this
  /// on.
  final bool traceContent;

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
