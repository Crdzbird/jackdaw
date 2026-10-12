import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_openai/jackdaw_openai.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

Map<String, Object?> callChunk(Map<String, Object?> delta, [String? reason]) =>
    {
      'choices': [
        {
          'delta': {
            'tool_calls': [delta],
          },
          'finish_reason': ?reason,
        },
      ],
    };

void main() {
  test('assembles tool calls streamed in fragments', () async {
    final model = OpenAiModel(
      model: 'm',
      client: replying(
        sseBody([
          callChunk({
            'index': 1,
            'id': 'b',
            'function': {'name': 'two', 'arguments': ''},
          }),
          callChunk({
            'index': 0,
            'id': 'a',
            'function': {'name': 'one', 'arguments': '{"x":'},
          }),
          callChunk({
            'index': 0,
            'function': {'arguments': '1}'},
          }),
          callChunk({
            'index': 2,
            'id': 'c',
            'function': {'name': 'bad', 'arguments': '{oops'},
          }, 'tool_calls'),
          callChunk({'id': 'no-index'}),
        ]),
      ),
    );
    final events = await model
        .generate(const ModelRequest(messages: []))
        .toList();
    final calls = events.whereType<ToolCallEvent>().map((e) => e.call).toList();
    expect(calls.map((c) => c.id), ['a', 'b', 'c']);
    expect(calls.map((c) => c.name), ['one', 'two', 'bad']);
    expect(calls[0].arguments, {'x': 1});
    expect(calls[1].arguments, <String, Object?>{});
    expect(calls[2].arguments, '{oops');
    expect((events.last as FinishEvent).reason, FinishReason.toolCalls);
  });

  test('maps every finish reason', () async {
    const reasons = {
      'length': FinishReason.length,
      'function_call': FinishReason.toolCalls,
      'content_filter': FinishReason.contentFilter,
      'mystery': FinishReason.other,
    };
    for (final MapEntry(:key, :value) in reasons.entries) {
      final model = OpenAiModel(
        model: 'm',
        client: replying(
          sseBody([
            {
              'choices': [
                {
                  'delta': {'content': ''},
                  'finish_reason': key,
                },
              ],
            },
          ]),
        ),
      );
      final events = await model
          .generate(const ModelRequest(messages: []))
          .toList();
      expect(events.single, isA<FinishEvent>());
      expect((events.single as FinishEvent).reason, value);
    }
  });
}
