@TestOn('browser')
library;

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_web/jackdaw_web.dart';
import 'package:test/test.dart';

import 'fake_wllama.dart';
import 'web_harness.dart';

void main() {
  late WebLocalModel model;

  setUp(() async {
    model = await WebLocalModel.open(
      modelUrl: 'https://models.example/qwen.gguf',
      moduleUrl: fakeWllamaUrl(),
      wasmUrl: 'https://cdn.example/wllama.wasm',
      contextTokens: 2048,
    );
  });

  test('loads the model and streams text with usage', () async {
    script([
      chunk({'content': 'Hel'}),
      chunk({'content': 'lo'}, finish: 'stop'),
      {
        'choices': <Object?>[],
        'usage': {'prompt_tokens': 7, 'completion_tokens': 2},
      },
    ]);
    final events = await model
        .generate(
          ModelRequest(
            messages: [Message.user('hi')],
            options: const GenerationOptions(maxOutputTokens: 32),
            responseSchema: const Schema.boolean(),
          ),
        )
        .toList();
    final finish = events.last as FinishEvent;
    expect(events.whereType<TextDelta>().map((e) => e.text), ['Hel', 'lo']);
    expect([finish.usage.inputTokens, finish.usage.outputTokens], [7, 2]);
    expect(model.id, 'web/qwen.gguf');
    expect(state('url'), 'https://models.example/qwen.gguf');
    expect((state('params')! as Map)['n_ctx'], 2048);
    expect(
      (state('paths')! as Map)['default'],
      'https://cdn.example/wllama.wasm',
    );
    final options = state('options')! as Map;
    expect(options['max_tokens'], 32);
    expect(options['grammar'], startsWith('root ::= boolean'));
    expect(options.containsKey('response_format'), isFalse);
    expect(options['stream'], isTrue);
  });

  test('cancelling aborts the completion', () async {
    script([
      for (var i = 0; i < 50; i++) chunk({'content': '$i'}),
    ]);
    final first = await model.generate(const ModelRequest(messages: [])).first;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect((first as TextDelta).text, '0');
    expect(state('aborted'), isTrue);
  });
}
