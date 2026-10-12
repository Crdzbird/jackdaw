import 'package:jackdaw/src/agent/agent_event.dart';
import 'package:jackdaw/src/agent/agent_stop_reason.dart';
import 'package:jackdaw/src/agent/agent_turn.dart';
import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/message/role.dart';
import 'package:jackdaw/src/model/generation_options.dart';
import 'package:jackdaw/src/model/language_model.dart';
import 'package:jackdaw/src/model/model_request.dart';
import 'package:jackdaw/src/model/usage.dart';
import 'package:jackdaw/src/tool/tool.dart';
import 'package:jackdaw/src/tool/tool_box.dart';

/// Runs a model in a loop, executing the tools it asks for, until it
/// answers or [maxSteps] model calls have been made.
///
/// Tool calls from one model turn run concurrently. Cancelling the stream
/// returned by [run] cancels the in-flight model call.
final class Agent {
  /// Creates an agent backed by [model].
  const factory({
    required LanguageModel model,
    List<Tool<Object?>> tools,
    String? instructions,
    int maxSteps,
    GenerationOptions options,
  }) = Agent._;

  const new _({
    required this.model,
    this.tools = const [],
    this.instructions,
    this.maxSteps = 8,
    this.options = const GenerationOptions(),
  });

  /// The model that decides what to do.
  final LanguageModel model;

  /// Tools the model may call.
  final List<Tool<Object?>> tools;

  /// System instructions placed before the history.
  final String? instructions;

  /// Maximum number of model calls in one run.
  final int maxSteps;

  /// Sampling settings for every model call.
  final GenerationOptions options;

  /// Streams one run over [history].
  Stream<AgentEvent> run(List<Message> history) async* {
    final toolBox = ToolBox(tools);
    final transcript = [
      if (instructions case final text?) Message.system(text),
      ...history,
    ];
    var usage = const Usage();
    for (var step = 0; step < maxSteps; step++) {
      final turn = AgentTurn();
      yield* turn.drive(model.generate(_request(transcript, toolBox)));
      usage += turn.usage;
      transcript.add(turn.message);
      if (turn.calls.isEmpty) {
        yield _finish(transcript, usage, AgentStopReason.completed);
        return;
      }
      final results = await toolBox.runAll(turn.calls);
      for (final result in results) {
        yield AgentToolResult(result);
      }
      transcript.add(Message(role: Role.tool, parts: results));
    }
    yield _finish(transcript, usage, AgentStopReason.stepLimit);
  }

  /// Runs over [history] and returns only the final event.
  Future<AgentFinished> complete(List<Message> history) async {
    final events = await run(history).toList();
    return events.whereType<AgentFinished>().single;
  }

  ModelRequest _request(List<Message> transcript, ToolBox toolBox) =>
      ModelRequest(
        messages: List.unmodifiable(transcript),
        tools: toolBox.specs,
        options: options,
      );

  AgentFinished _finish(
    List<Message> messages,
    Usage usage,
    AgentStopReason reason,
  ) => AgentFinished(
    messages: List.unmodifiable(messages),
    usage: usage,
    reason: reason,
  );
}
