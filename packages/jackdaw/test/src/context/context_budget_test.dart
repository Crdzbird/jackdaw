import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

final _counter = TokenCounter.fromText((text) => text.length, overhead: 0);

Message assistantCall(String id) => Message(
  role: Role.assistant,
  parts: [ToolCallPart(id: id, name: 't', arguments: const {})],
);

Message toolResult(String id) => Message(
  role: Role.tool,
  parts: [ToolResultPart(callId: id, name: 't', output: 'xxxxxxxxxx')],
);

void main() {
  final history = [
    Message.user('aaaaaaaaaa'),
    assistantCall('1'),
    toolResult('1'),
    Message.assistant('bbbbbbbbbb'),
    Message.user('cccccccccc'),
    Message.assistant('dd'),
  ];

  test('keeps everything that fits', () {
    final budget = ContextBudget(maxTokens: 1000, counter: _counter);
    expect(budget.fit(history), history);
    expect(
      budget.fit([Message.assistant('x'), Message.user('y')]),
      hasLength(2),
    );
  });

  test('drops whole exchanges and restarts at a user message', () {
    final fitted = ContextBudget(maxTokens: 30, counter: _counter).fit(history);
    expect(fitted.first.text, 'cccccccccc');
    expect(fitted, hasLength(2));
  });

  test('always keeps the latest user turn', () {
    final fitted = ContextBudget(maxTokens: 1, counter: _counter).fit(history);
    expect(fitted.map((m) => m.text), ['cccccccccc', 'dd']);
    expect(const ContextBudget(maxTokens: 1).fit(const []), isEmpty);
  });

  test('counters measure every part', () {
    expect(_counter.count(assistantCall('1')), 't {}'.length);
    expect(_counter.count(toolResult('1')), '"xxxxxxxxxx"'.length);
    final estimate = TokenCounter.estimate(charsPerToken: 2, overhead: 1);
    expect(estimate.count(Message.user('abcd')), 3);
    expect(const EstimatingTokenCounter().count(Message.user('')), 4);
    expect(
      messageContent(
        const Message(
          role: Role.assistant,
          parts: [
            ReasoningPart(provider: 'p', text: 'r'),
            TextPart('t'),
          ],
        ),
      ),
      'r\nt',
    );
  });

  test('agents send only what fits the budget', () async {
    final model = _Recorder();
    final agent = Agent(
      model: model,
      instructions: 'Be brief.',
      budget: ContextBudget(maxTokens: 30, counter: _counter),
    );
    await agent.run(history.sublist(0, 5)).drain<void>();
    expect(model.last.map((m) => m.text), ['Be brief.', 'cccccccccc']);
  });
}

final class _Recorder implements LanguageModel {
  List<Message> last = const [];

  @override
  String get id => 'test/recorder';

  @override
  Stream<ModelEvent> generate(ModelRequest request) {
    last = request.messages;
    return Stream.value(const FinishEvent(reason: FinishReason.stop));
  }
}
