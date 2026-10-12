import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_test/jackdaw_test.dart';
import 'package:test/test.dart';

void main() {
  const request = ModelRequest(messages: []);

  test('replays turns in order and records requests', () async {
    final model = ScriptedModel([
      textTurn(['a', 'b']),
      textTurn(['c']),
    ]);
    final first = await model.generate(request).toList();
    final second = await model.generate(request).toList();
    expect(first.whereType<TextDelta>().map((e) => e.text), ['a', 'b']);
    expect(second.whereType<TextDelta>().map((e) => e.text), ['c']);
    expect(model.requests, [request, request]);
    expect(model.remaining, 0);
    expect(model.id, 'test/scripted');
  });

  test('fails once the script is exhausted', () {
    final model = ScriptedModel(const [], id: 'x');
    expect(model.generate(request), emitsError(isA<StateError>()));
    expect(model.id, 'x');
  });

  test('builds tool call turns', () {
    const call = ToolCallPart(id: '1', name: 't', arguments: {});
    final turn = toolCallTurn([call], usage: const Usage(inputTokens: 3));
    final finish = turn.last as FinishEvent;
    expect((turn.first as ToolCallEvent).call, same(call));
    expect(finish.reason, FinishReason.toolCalls);
    expect(finish.usage.inputTokens, 3);
  });
}
