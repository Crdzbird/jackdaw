import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

final class _Eager implements LanguageModel {
  final List<ModelRequest> requests = [];

  @override
  String get id => 'test/eager';

  @override
  Stream<ModelEvent> generate(ModelRequest request) {
    requests.add(request);
    if (request.tools.isEmpty) {
      return Stream.fromIterable([
        const TextDelta('done'),
        const FinishEvent(reason: FinishReason.stop),
      ]);
    }
    return Stream.fromIterable([
      ToolCallEvent(
        ToolCallPart(
          id: 'c${requests.length}',
          name: 'echo',
          arguments: const {},
        ),
      ),
      const FinishEvent(reason: FinishReason.toolCalls),
    ]);
  }
}

Tool<Object?> echo({int? limit, bool fail = false}) => Tool<Object?>(
  name: 'echo',
  description: 'Echo.',
  input: const ObjectSchema(properties: {}),
  decode: (json) => json,
  run: (_) => fail ? throw const ToolFailure({'fix': 'this'}) : 'ok',
  maxCallsPerTurn: limit,
);

void main() {
  test('a failure carries structured output and is an error', () async {
    final result = await echo(fail: true)
        .invoke(const ToolCallPart(id: 'c', name: 'echo', arguments: {}));
    expect(result.isError, isTrue);
    expect(result.output, {'fix': 'this'});
    expect('${const ToolFailure(1)}', 'ToolFailure: 1');
  });

  test('a tool stops being offered after its successful calls', () async {
    final model = _Eager();
    final done = await Agent(
      model: model,
      tools: [echo(limit: 1)],
    ).complete([Message.user('go')]);
    expect(done.text, 'done');
    expect(model.requests.map((r) => r.tools.length), [1, 0]);
  });

  test('failed calls do not count and a new user message resets', () async {
    final model = _Eager();
    final failing = await Agent(
      model: model,
      tools: [echo(limit: 1, fail: true)],
      maxSteps: 3,
    ).complete([Message.user('go')]);
    expect(failing.reason, AgentStopReason.stepLimit);
    expect(model.requests.map((r) => r.tools.length), [1, 1, 1]);
    final again = _Eager();
    await Agent(model: again, tools: [echo(limit: 1)]).complete([
      Message.user('a'),
      const Message(
        role: Role.assistant,
        parts: [ToolCallPart(id: 'c', name: 'echo', arguments: {})],
      ),
      const Message(
        role: Role.tool,
        parts: [ToolResultPart(callId: 'c', name: 'echo', output: 'ok')],
      ),
      Message.assistant('done'),
      Message.user('b'),
    ]);
    expect(again.requests.first.tools, hasLength(1));
  });
}
