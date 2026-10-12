import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_openai/src/open_ai_request_encoder.dart';
import 'package:test/test.dart';

void main() {
  test('encodes every role, tools and options', () {
    final body = encodeChatRequest(
      'gpt-x',
      ModelRequest(
        messages: [
          Message.system('rules'),
          Message.user('hi'),
          const Message(
            role: Role.assistant,
            parts: [
              ToolCallPart(id: '1', name: 'add', arguments: {'a': 1}),
              ToolCallPart(id: '2', name: 'add', arguments: '{raw'),
            ],
          ),
          const Message(
            role: Role.tool,
            parts: [ToolResultPart(callId: '1', name: 'add', output: 2)],
          ),
          Message.assistant('done'),
        ],
        tools: const [
          ToolSpec(
            name: 'add',
            description: 'Adds',
            input: ObjectSchema(properties: {}),
          ),
        ],
        options: const GenerationOptions(temperature: 0.5, maxOutputTokens: 10),
      ),
    );
    final messages = body['messages']! as List<Object?>;
    expect(messages[0], {'role': 'system', 'content': 'rules'});
    expect(messages[1], {'role': 'user', 'content': 'hi'});
    expect(messages[2], {
      'role': 'assistant',
      'content': null,
      'tool_calls': [
        {
          'id': '1',
          'type': 'function',
          'function': {'name': 'add', 'arguments': '{"a":1}'},
        },
        {
          'id': '2',
          'type': 'function',
          'function': {'name': 'add', 'arguments': '{raw'},
        },
      ],
    });
    expect(messages[3], {'role': 'tool', 'tool_call_id': '1', 'content': '2'});
    expect(messages[4], {'role': 'assistant', 'content': 'done'});
    expect((body['tools']! as List<Object?>).single, {
      'type': 'function',
      'function': {
        'name': 'add',
        'description': 'Adds',
        'parameters': const ObjectSchema(properties: {}).toJson(),
      },
    });
    expect(body['temperature'], 0.5);
    expect(body['max_completion_tokens'], 10);
    expect(body['stream'], isTrue);
  });

  test('maps the response schema to response_format', () {
    final body = encodeChatRequest(
      'm',
      const ModelRequest(messages: [], responseSchema: Schema.boolean()),
    );
    expect(body['response_format'], {
      'type': 'json_schema',
      'json_schema': {
        'name': 'response',
        'schema': {'type': 'boolean'},
      },
    });
  });

  test('omits optional fields', () {
    final body = encodeChatRequest('m', const ModelRequest(messages: []));
    expect(body.keys, ['model', 'messages', 'stream', 'stream_options']);
  });
}
