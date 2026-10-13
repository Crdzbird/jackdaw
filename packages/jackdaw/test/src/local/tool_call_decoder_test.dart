import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

Future<List<ModelEvent>> _decode(List<ModelEvent> events) =>
    Stream.fromIterable(events).transform(ToolCallDecoder()).toList();

const _stop = FinishEvent(
  reason: FinishReason.stop,
  usage: Usage(outputTokens: 9),
);

void main() {
  test('text streams through unchanged', () async {
    final events = await _decode(const [
      TextDelta('  '),
      TextDelta('Hello'),
      TextDelta(' there'),
      _stop,
    ]);
    expect(events.whereType<TextDelta>().map((e) => e.text), [
      '  Hello',
      ' there',
    ]);
    expect((events.last as FinishEvent).reason, FinishReason.stop);
  });

  test('tool call blocks become calls with unique ids', () async {
    final events = await _decode(const [
      TextDelta('<tool_'),
      TextDelta(
        'call>\n{"name": "w", "arguments": {"city": "Lima"}}\n</tool_call>',
      ),
      TextDelta(
        '\n<tool_call>\n{"name": "now", "arguments": {}}\n</tool_call>',
      ),
      _stop,
    ]);
    final calls = events.whereType<ToolCallEvent>().map((e) => e.call).toList();
    expect(events.whereType<TextDelta>(), isEmpty);
    expect(calls.map((c) => c.name), ['w', 'now']);
    expect(calls.first.arguments, {'city': 'Lima'});
    expect(calls.first.id, isNot(calls.last.id));
    final finish = events.last as FinishEvent;
    expect(finish.reason, FinishReason.toolCalls);
    expect(finish.usage.outputTokens, 9);
  });

  test('cut off or broken calls fail the stream', () async {
    await expectLater(
      _decode(const [
        TextDelta('<tool_call>\n{"name": "w", "argu'),
        FinishEvent(reason: FinishReason.length),
      ]),
      throwsFormatException,
    );
    await expectLater(
      _decode(const [TextDelta('<tool_call>\n{oops}\n</tool_call>'), _stop]),
      throwsFormatException,
    );
    expect(parseToolCalls('<tool_call>\n{"x": 1}\n</tool_call>', 'c'), isNull);
    expect(parseToolCalls('no calls', 'c'), isNull);
  });
}
