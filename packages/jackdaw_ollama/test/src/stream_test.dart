import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_ollama/jackdaw_ollama.dart';
import 'package:test/test.dart';

import 'replay.dart';

void main() {
  test('collects thinking and tool calls without ids', () async {
    final (events, _) = await replay(
      '{"message":{"thinking":"Hmm. "}}\n\n'
      '{"message":{"thinking":"Ok.","tool_calls":[{"function":{"name":"a"}},'
      '{"nope":1}]}}\n'
      '{"done":true}\n',
    );
    final reasoning = events.whereType<ReasoningEvent>().single.part;
    final call = events.whereType<ToolCallEvent>().single.call;
    expect([reasoning.text, reasoning.provider], ['Hmm. Ok.', 'ollama']);
    expect([call.id, call.arguments], ['call_0', <String, Object?>{}]);
    final finish = events.last as FinishEvent;
    expect(finish.reason, FinishReason.toolCalls);
    expect(finish.usage.inputTokens, isNull);
  });

  test('unknown done reasons and stream errors', () async {
    final (events, _) = await replay('{"done":true,"done_reason":"unload"}');
    expect((events.single as FinishEvent).reason, FinishReason.other);
    await expectLater(
      replay('{"error":"out of memory"}'),
      throwsA(
        isA<ProviderException>().having((e) => e.message, 'm', 'out of memory'),
      ),
    );
    await expectLater(
      replay('{"error":"model not found"}', status: 404),
      throwsA(isA<ProviderException>().having((e) => e.statusCode, 's', 404)),
    );
  });

  test('defaults', () {
    const model = OllamaModel(model: 'llama3.2');
    expect(model.id, 'ollama/llama3.2');
    expect([
      model.baseUrl,
      model.numCtx,
      model.topK,
      model.keepAlive,
    ], everyElement(isNull));
    expect(model.headers, isEmpty);
  });
}
