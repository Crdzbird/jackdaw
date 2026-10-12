import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_anthropic/src/anthropic_request_encoder.dart';
import 'package:test/test.dart';

void main() {
  test('maps the transcript and replays only Anthropic reasoning', () {
    final body = encodeMessagesRequest(
      'claude-opus-5-5',
      ModelRequest(
        messages: [
          Message.system('Be brief.'),
          Message.user('Weather?'),
          const Message(
            role: Role.assistant,
            parts: [
              ReasoningPart(
                provider: 'anthropic',
                data: {'type': 'thinking', 'thinking': '', 'signature': 's'},
              ),
              ReasoningPart(provider: 'gemini', data: {'thought': true}),
              TextPart(''),
              TextPart('Checking.'),
              ToolCallPart(id: 't1', name: 'w', arguments: {'city': 'Lima'}),
              ToolCallPart(id: 't2', name: 'w', arguments: '{bad'),
            ],
          ),
          const Message(
            role: Role.tool,
            parts: [
              ToolResultPart(callId: 't1', name: 'w', output: {'c': 21}),
              ToolResultPart(
                callId: 't2',
                name: 'w',
                output: 'boom',
                isError: true,
              ),
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
        options: const GenerationOptions(temperature: 0.3, maxOutputTokens: 99),
        responseSchema: const Schema.boolean(),
      ),
      defaultMaxTokens: 64000,
    );
    expect(body['system'], 'Be brief.');
    expect(body['max_tokens'], 99);
    expect(body['temperature'], 0.3);
    expect(body['output_config'], {
      'format': {
        'type': 'json_schema',
        'schema': {'type': 'boolean'},
      },
    });
    final messages = body['messages']! as List<Object?>;
    expect(messages, hasLength(3));
    expect(messages[1], {
      'role': 'assistant',
      'content': [
        {'type': 'thinking', 'thinking': '', 'signature': 's'},
        {'type': 'text', 'text': 'Checking.'},
        {
          'type': 'tool_use',
          'id': 't1',
          'name': 'w',
          'input': {'city': 'Lima'},
        },
        {
          'type': 'tool_use',
          'id': 't2',
          'name': 'w',
          'input': <String, Object?>{},
        },
      ],
    });
    expect(messages[2], {
      'role': 'user',
      'content': [
        {'type': 'tool_result', 'tool_use_id': 't1', 'content': '{"c":21}'},
        {
          'type': 'tool_result',
          'tool_use_id': 't2',
          'content': 'boom',
          'is_error': true,
        },
      ],
    });
    expect((body['tools']! as List<Object?>).single, {
      'name': 'w',
      'description': 'Weather',
      'input_schema': const ObjectSchema(properties: {}).toJson(),
    });
  });
}
