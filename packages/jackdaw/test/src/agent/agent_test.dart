import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_test/jackdaw_test.dart';
import 'package:test/test.dart';

final adder = Tool<List<int>>(
  name: 'add',
  description: 'Adds two integers',
  input: const ObjectSchema(
    properties: {'a': Schema.integer(), 'b': Schema.integer()},
    required: ['a', 'b'],
  ),
  decode: (json) => [json['a']! as int, json['b']! as int],
  run: (pair) => pair[0] + pair[1],
);

ToolCallPart add(String id, int a, int b) =>
    ToolCallPart(id: id, name: 'add', arguments: {'a': a, 'b': b});

void main() {
  test('streams text and finishes when the model answers', () async {
    final model = ScriptedModel([
      textTurn(['Hel', 'lo'], usage: const Usage(inputTokens: 5)),
    ]);
    final agent = Agent(model: model, instructions: 'Be brief.');
    final events = await agent.run([Message.user('hi')]).toList();
    final finished = events.last as AgentFinished;
    expect(events.whereType<AgentTextDelta>().map((e) => e.text), [
      'Hel',
      'lo',
    ]);
    expect(finished.reason, AgentStopReason.completed);
    expect(finished.text, 'Hello');
    expect(finished.usage.inputTokens, 5);
    expect(model.requests.single.messages.first.role, Role.system);
  });

  test('runs requested tools in parallel and feeds results back', () async {
    final model = ScriptedModel([
      toolCallTurn([add('1', 1, 2), add('2', 3, 4)]),
      textTurn(['3 and 7']),
    ]);
    final agent = Agent(model: model, tools: [adder]);
    final events = await agent.run([Message.user('sums')]).toList();
    final results = events.whereType<AgentToolResult>().map((e) => e.result);
    expect(events.whereType<AgentToolCall>(), hasLength(2));
    expect(results.map((r) => r.output), [3, 7]);
    final second = model.requests[1].messages;
    expect(second.map((m) => m.role), [Role.user, Role.assistant, Role.tool]);
    expect(model.requests.first.tools.single.name, 'add');
  });

  test('stops at the step limit', () async {
    final model = ScriptedModel([
      toolCallTurn([add('1', 1, 1)]),
    ]);
    final agent = Agent(model: model, tools: [adder], maxSteps: 1);
    final finished = await agent.complete([Message.user('loop')]);
    expect(finished.reason, AgentStopReason.stepLimit);
    expect(finished.messages.last.role, Role.tool);
  });

  test('defaults', () {
    final agent = Agent(model: ScriptedModel(const []));
    expect(agent.maxSteps, 8);
    expect(agent.tools, isEmpty);
    expect(agent.instructions, isNull);
    expect(agent.options.temperature, isNull);
  });
}
