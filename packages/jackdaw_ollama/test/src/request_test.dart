import 'dart:convert';

import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import 'replay.dart';

const _done = '{"message":{"content":""},"done":true,"done_reason":"length"}';

void main() {
  test('sends history, tools, schema and Ollama options', () async {
    final (events, sent) = await replay(
      _done,
      request: ModelRequest(
        messages: [
          Message.system('Be brief.'),
          Message.user('Weather?'),
          const Message(
            role: Role.assistant,
            parts: [
              ToolCallPart(id: 'c1', name: 'w', arguments: {'city': 'Lima'}),
              ToolCallPart(id: 'c2', name: 'w', arguments: '{bad'),
            ],
          ),
          const Message(
            role: Role.tool,
            parts: [
              ToolResultPart(callId: 'c1', name: 'w', output: {'c': 21}),
              ToolResultPart(callId: 'c2', name: 'w', output: 'oops'),
            ],
          ),
        ],
        tools: const [
          ToolSpec(
            name: 'w',
            description: 'Weather',
            input: ObjectSchema(properties: {}),
          ),
        ],
        options: const GenerationOptions(temperature: 0, maxOutputTokens: 64),
        responseSchema: const Schema.boolean(),
      ),
    );
    final body = jsonDecode(sent.body) as Map<String, Object?>;
    final messages = body['messages']! as List<Object?>;
    expect(messages[0], {'role': 'system', 'content': 'Be brief.'});
    expect((messages[2]! as Map)['tool_calls'], [
      {
        'id': 'c1',
        'function': {
          'name': 'w',
          'arguments': {'city': 'Lima'},
        },
      },
      {
        'id': 'c2',
        'function': {'name': 'w', 'arguments': <String, Object?>{}},
      },
    ]);
    expect(messages[3], {
      'role': 'tool',
      'tool_name': 'w',
      'content': '{"c":21}',
    });
    expect(messages[4], {'role': 'tool', 'tool_name': 'w', 'content': 'oops'});
    expect(body['format'], {'type': 'boolean'});
    expect(body['options'], {
      'temperature': 0,
      'num_predict': 64,
      'num_ctx': 4096,
      'top_k': 40,
    });
    expect(body['keep_alive'], '5m');
    expect(
      (body['tools']! as List<Object?>).single,
      isA<Map<String, Object?>>(),
    );
    expect((events.single as FinishEvent).reason, FinishReason.length);
  });
}
