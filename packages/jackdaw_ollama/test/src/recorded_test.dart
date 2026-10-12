@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import 'replay.dart';

String fixture(String name) =>
    File('test/src/fixtures/$name.ndjson').readAsStringSync();

void main() {
  test('recorded text answer from Ollama 0.33.3', () async {
    final (events, sent) = await replay(fixture('text'));
    final finish = events.last as FinishEvent;
    expect(events.whereType<TextDelta>().map((e) => e.text).join(), isNotEmpty);
    expect(finish.reason, FinishReason.stop);
    expect([finish.usage.inputTokens, finish.usage.outputTokens], [35, 4]);
    expect('${sent.url}', 'http://box:11434/api/chat');
  });

  test('recorded tool call keeps the server id', () async {
    final (events, _) = await replay(fixture('tools'));
    final call = events.whereType<ToolCallEvent>().single.call;
    expect(call.id, 'call_5la8k3mh');
    expect(call.name, 'get_weather');
    expect(call.arguments, {'city': 'Lima'});
    expect((events.last as FinishEvent).reason, FinishReason.toolCalls);
  });

  test('recorded schema answer is valid JSON', () async {
    final (events, _) = await replay(fixture('format'));
    final text = events.whereType<TextDelta>().map((e) => e.text).join();
    const schema = ObjectSchema(
      properties: {'answer': Schema.boolean()},
      required: ['answer'],
    );
    expect(schema.validate(jsonDecode(text)), isEmpty);
  });
}
