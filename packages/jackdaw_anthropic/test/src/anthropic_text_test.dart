import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_anthropic/jackdaw_anthropic.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('streams text, usage and the stop reason', () async {
    late http.Request sent;
    final model = AnthropicModel(
      model: 'claude-opus-5-5',
      apiKey: const Secret('sk-ant-test'),
      baseUrl: Uri.parse('https://proxy.example/v1'),
      client: replying(
        sse([
          messageStart,
          {'type': 'ping'},
          start(0, {'type': 'text', 'text': ''}),
          delta(0, {'type': 'text_delta', 'text': 'Hel'}),
          delta(0, {'type': 'text_delta', 'text': 'lo'}),
          stop(0),
          messageDelta('end_turn', 12),
          {'type': 'message_stop'},
        ]),
        onRequest: (request) => sent = request,
      ),
    );
    final events = await model
        .generate(ModelRequest(messages: [Message.user('hi')]))
        .toList();
    final finish = events.last as FinishEvent;
    expect(events.whereType<TextDelta>().map((e) => e.text), ['Hel', 'lo']);
    expect(finish.reason, FinishReason.stop);
    expect([finish.usage.inputTokens, finish.usage.outputTokens], [25, 12]);
    expect('${sent.url}', 'https://proxy.example/v1/messages');
    expect(sent.headers['x-api-key'], 'sk-ant-test');
    expect(sent.headers['anthropic-version'], '2023-06-01');
    expect((jsonDecode(sent.body) as Map)['max_tokens'], 64000);
    expect(model.id, 'anthropic/claude-opus-5-5');
  });

  test('a text block may start with text', () async {
    final model = AnthropicModel(
      model: 'm',
      apiKey: const Secret('k'),
      client: replying(
        sse([
          start(0, {'type': 'text', 'text': 'Hi'}),
          stop(0),
          messageDelta('stop_sequence', 1),
        ]),
      ),
    );
    final events = await model
        .generate(const ModelRequest(messages: []))
        .toList();
    expect((events.first as TextDelta).text, 'Hi');
    expect((events.last as FinishEvent).usage.inputTokens, isNull);
  });
}
