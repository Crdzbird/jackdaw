import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_openai/jackdaw_openai.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

const request = ModelRequest(messages: []);

void main() {
  test('streams text, finish reason and usage', () async {
    late http.Request sent;
    final model = OpenAiModel(
      model: 'gpt-x',
      apiKey: const Secret('sk-test'),
      baseUrl: Uri.parse('http://localhost:11434/v1'),
      headers: const {'x-trace': '1'},
      client: replying(
        sseBody([
          textChunk('Hel'),
          textChunk('lo'),
          {
            'choices': [
              {'delta': <String, Object?>{}, 'finish_reason': 'stop'},
            ],
          },
          {
            'choices': <Object?>[],
            'usage': {'prompt_tokens': 4, 'completion_tokens': 2},
          },
        ]),
        onRequest: (r) => sent = r as http.Request,
      ),
    );
    final events = await model.generate(request).toList();
    final finish = events.last as FinishEvent;
    expect(events.whereType<TextDelta>().map((e) => e.text), ['Hel', 'lo']);
    expect(finish.reason, FinishReason.stop);
    expect([finish.usage.inputTokens, finish.usage.outputTokens], [4, 2]);
    expect('${sent.url}', 'http://localhost:11434/v1/chat/completions');
    expect(sent.headers['authorization'], 'Bearer sk-test');
    expect(sent.headers['x-trace'], '1');
    expect((jsonDecode(sent.body) as Map)['model'], 'gpt-x');
    expect(model.id, 'openai/gpt-x');
  });

  test('uses the OpenAI endpoint and omits auth without a key', () async {
    late http.BaseRequest sent;
    final model = OpenAiModel(
      model: 'm',
      client: replying(sseBody(const []), onRequest: (r) => sent = r),
    );
    await model.generate(request).drain<void>();
    expect('${sent.url}', 'https://api.openai.com/v1/chat/completions');
    expect(sent.headers.containsKey('authorization'), isFalse);
  });

  test('maps error responses to ProviderException', () {
    final model = OpenAiModel(
      model: 'm',
      client: replying(
        Stream.value(utf8.encode('{"error":{"message":"slow down"}}')),
        status: 429,
        headers: const {'retry-after': '3'},
      ),
    );
    expect(
      model.generate(request).toList(),
      throwsA(
        isA<ProviderException>()
            .having((e) => e.message, 'message', 'slow down')
            .having((e) => e.statusCode, 'status', 429)
            .having((e) => e.retryAfter, 'retry', const Duration(seconds: 3)),
      ),
    );
  });

  test('falls back to the status code for non-JSON errors', () {
    final model = OpenAiModel(
      model: 'm',
      client: replying(Stream.value(utf8.encode('<html>')), status: 502),
    );
    expect(
      model.generate(request).toList(),
      throwsA(
        isA<ProviderException>().having((e) => e.message, 'm', 'HTTP 502'),
      ),
    );
  });
}
