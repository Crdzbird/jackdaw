import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  test('tools and schema go into the system message', () {
    final pairs = localPrompt(
      ModelRequest(
        messages: [Message.system('Be brief.'), Message.user('Hi')],
        tools: const [
          ToolSpec(
            name: 'now',
            description: 'Current time',
            input: ObjectSchema(properties: {}),
          ),
        ],
        responseSchema: const Schema.boolean(),
      ),
    );
    expect(pairs, hasLength(2));
    final (role, system) = pairs.first;
    expect(role, 'system');
    expect(system, startsWith('Be brief.\n\n# Tools'));
    expect(system, contains('"name":"now"'));
    expect(system, contains('<tool_call>'));
    expect(system, endsWith('{"type":"boolean"}'));
  });

  test('tool calls and results are written back into the history', () {
    final pairs = localPrompt(
      ModelRequest(
        messages: [
          Message.user('Weather?'),
          const Message(
            role: Role.assistant,
            parts: [
              TextPart('Checking.'),
              ToolCallPart(id: 'c1', name: 'w', arguments: {'city': 'Lima'}),
            ],
          ),
          const Message(
            role: Role.tool,
            parts: [ToolResultPart(callId: 'c1', name: 'w', output: 21)],
          ),
        ],
      ),
    );
    expect(pairs, [
      ('user', 'Weather?'),
      (
        'assistant',
        'Checking.\n<tool_call>\n{"name":"w","arguments":{"city":"Lima"}}'
            '\n</tool_call>',
      ),
      ('user', '<tool_response>\n{"name":"w","content":21}\n</tool_response>'),
    ]);
    expect(localPrompt(ModelRequest(messages: [Message.user('x')])), [
      ('user', 'x'),
    ]);
    final schemaOnly = localPrompt(
      ModelRequest(
        messages: [Message.user('x')],
        responseSchema: const Schema.boolean(),
      ),
    );
    expect(schemaOnly.first.$1, 'system');
    expect(schemaOnly.first.$2, startsWith('Reply with JSON only'));
  });
}
