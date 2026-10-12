import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('streams text and usage from the right endpoint', () async {
    final (events, sent) = await run([
      candidate([
        {'text': 'Hel'},
      ]),
      {
        ...candidate([
          {'text': 'lo'},
        ], finish: 'STOP'),
        'usageMetadata': {
          'promptTokenCount': 9,
          'candidatesTokenCount': 3,
          'thoughtsTokenCount': 4,
        },
      },
    ]);
    final finish = events.last as FinishEvent;
    expect(events.whereType<TextDelta>().map((e) => e.text), ['Hel', 'lo']);
    expect(finish.reason, FinishReason.stop);
    expect([finish.usage.inputTokens, finish.usage.outputTokens], [9, 7]);
    expect(
      '${sent.url}',
      'https://proxy.example/v1beta/models/gemini-3.8-flash:streamGenerateContent?alt=sse',
    );
    expect(sent.headers['x-goog-api-key'], 'g-key');
  });

  test('keeps thought signatures for replay', () async {
    final (events, _) = await run([
      candidate([
        {'text': 'Think ', 'thought': true},
        {'text': 'more.', 'thought': true, 'thoughtSignature': 'sig-a'},
      ]),
      candidate([
        {
          'functionCall': {
            'name': 'weather',
            'args': {'city': 'Lima'},
          },
          'thoughtSignature': 'sig-b',
        },
        {
          'functionCall': {'id': 'fc-2', 'name': 'now'},
        },
      ], finish: 'STOP'),
    ]);
    final reasoning = events.whereType<ReasoningEvent>().single.part;
    final calls = events.whereType<ToolCallEvent>().map((e) => e.call).toList();
    expect(events.first, isA<ReasoningEvent>());
    expect(reasoning.text, 'Think more.');
    expect(reasoning.data, {
      'text': 'Think more.',
      'thought': true,
      'thoughtSignature': 'sig-a',
    });
    expect(calls.first.id, 'call_0');
    expect(calls.first.providerData, {'thoughtSignature': 'sig-b'});
    expect(calls.last.id, 'fc-2');
    expect(calls.last.arguments, <String, Object?>{});
    expect((events.last as FinishEvent).reason, FinishReason.toolCalls);
  });

  test('flushes trailing thoughts and maps finish reasons', () async {
    final (thinking, _) = await run([
      candidate([
        {'text': 'Only thinking.', 'thought': true},
      ], finish: 'MAX_TOKENS'),
    ]);
    expect(thinking.first, isA<ReasoningEvent>());
    expect((thinking.last as FinishEvent).reason, FinishReason.length);
    const reasons = {
      'SAFETY': FinishReason.contentFilter,
      'MALFORMED_FUNCTION_CALL': FinishReason.other,
    };
    for (final MapEntry(:key, :value) in reasons.entries) {
      final (events, _) = await run([candidate(const [], finish: key)]);
      expect((events.last as FinishEvent).reason, value);
    }
    final (blocked, _) = await run([
      {
        'promptFeedback': {'blockReason': 'SAFETY'},
      },
    ]);
    expect((blocked.single as FinishEvent).reason, FinishReason.contentFilter);
  });
}
