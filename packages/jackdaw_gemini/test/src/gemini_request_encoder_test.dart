import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_gemini/src/gemini_request_encoder.dart';
import 'package:test/test.dart';

void main() {
  test('maps the transcript and replays Gemini signatures', () {
    final body = encodeGenerateRequest(
      ModelRequest(
        messages: [
          Message.system('Be brief.'),
          Message.user('Weather?'),
          const Message(
            role: Role.assistant,
            parts: [
              ReasoningPart(
                provider: 'gemini',
                data: {'text': '', 'thought': true},
              ),
              ReasoningPart(provider: 'anthropic', data: {'type': 'thinking'}),
              TextPart(''),
              ToolCallPart(
                id: 'c1',
                name: 'w',
                arguments: {'city': 'Lima'},
                providerData: {'thoughtSignature': 's'},
              ),
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
        options: const GenerationOptions(temperature: 0.2, maxOutputTokens: 50),
        responseSchema: const Schema.boolean(),
      ),
    );
    final contents = body['contents']! as List<Object?>;
    expect(body['systemInstruction'], {
      'parts': [
        {'text': 'Be brief.'},
      ],
    });
    expect(contents[1], {
      'role': 'model',
      'parts': [
        {'text': '', 'thought': true},
        {
          'functionCall': {
            'id': 'c1',
            'name': 'w',
            'args': {'city': 'Lima'},
          },
          'thoughtSignature': 's',
        },
        {
          'functionCall': {
            'id': 'c2',
            'name': 'w',
            'args': <String, Object?>{},
          },
        },
      ],
    });
    expect((contents[2]! as Map)['parts'], [
      {
        'functionResponse': {
          'id': 'c1',
          'name': 'w',
          'response': {'c': 21},
        },
      },
      {
        'functionResponse': {
          'id': 'c2',
          'name': 'w',
          'response': {'result': 'oops'},
        },
      },
    ]);
    expect(
      ((body['tools']! as List).single as Map)['functionDeclarations'],
      hasLength(1),
    );
  });
}
