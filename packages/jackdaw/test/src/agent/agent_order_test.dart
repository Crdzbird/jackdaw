import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_test/jackdaw_test.dart';
import 'package:test/test.dart';

void main() {
  test('keeps reasoning, text and calls in the order produced', () async {
    const reasoning = ReasoningPart(
      provider: 'anthropic',
      text: 'think',
      data: {'signature': 's'},
    );
    const call = ToolCallPart(
      id: '1',
      name: 'echo',
      arguments: {},
      providerData: {'thoughtSignature': 'g'},
    );
    final model = ScriptedModel([
      [
        const ReasoningEvent(reasoning),
        const TextDelta('a'),
        const TextDelta('b'),
        const ToolCallEvent(call),
        const TextDelta('c'),
        const FinishEvent(reason: FinishReason.toolCalls),
      ],
      textTurn(['done']),
    ]);
    final echo = Tool<Object?>(
      name: 'echo',
      description: 'echo',
      input: const ObjectSchema(properties: {}),
      decode: (json) => json,
      run: (input) => input,
    );
    final events = await Agent(
      model: model,
      tools: [echo],
    ).run(const []).toList();
    final assistant = model.requests[1].messages.first;
    expect(events.whereType<AgentReasoning>().single.part, same(reasoning));
    expect(assistant.parts, hasLength(4));
    expect(assistant.parts[0], same(reasoning));
    expect((assistant.parts[1] as TextPart).text, 'ab');
    expect(assistant.parts[2], same(call));
    expect((assistant.parts[3] as TextPart).text, 'c');
    expect(reasoning.data['signature'], 's');
    expect(call.providerData['thoughtSignature'], 'g');
  });

  test('defaults for reasoning and provider data are empty', () {
    const part = ReasoningPart(provider: 'p');
    const call = ToolCallPart(id: '1', name: 'n', arguments: null);
    expect([part.text, part.data, call.providerData], ['', isEmpty, isEmpty]);
  });
}
