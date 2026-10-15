import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  const big = ObjectSchema(
    properties: {'name': Schema.string()},
    required: ['name'],
  );
  const short = Schema.summarized(big, summary: 'A named thing.');

  test('a summarized schema validates and compiles as its schema', () {
    expect(short.validate({'name': 'a'}), isEmpty);
    expect(short.validate(<String, Object?>{}), isNotEmpty);
    expect(short.toJson(), big.toJson());
    expect(GbnfCompiler().compile(short), GbnfCompiler().compile(big));
  });

  test('local prompts show the summary instead of the schema', () {
    expect(promptSchemaJson(short), {'description': 'A named thing.'});
    expect(promptSchemaJson(const ObjectSchema(properties: {'x': short})), {
      'type': 'object',
      'properties': {
        'x': {'description': 'A named thing.'},
      },
      'required': <String>[],
      'additionalProperties': false,
    });
    final prompt = localPrompt(
      ModelRequest(messages: [Message.user('Hi')], responseSchema: short),
    );
    expect(prompt.first.$2, contains('A named thing.'));
    expect(prompt.first.$2, isNot(contains('"name"')));
  });
}
