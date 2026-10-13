import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

const _weather = ToolSpec(
  name: 'get_weather',
  description: 'Weather for a city',
  input: ObjectSchema(
    properties: {'city': Schema.string()},
    required: ['city'],
  ),
);

const _time = ToolSpec(
  name: 'now',
  description: 'Current time',
  input: ObjectSchema(properties: {}),
);

void main() {
  test('the grammar offers each tool call or free text', () {
    final grammar = toolCallGrammar([_weather, _time]);
    expect(grammar, startsWith('root ::= rule'));
    expect(
      grammar,
      contains(r'"<tool_call>\n{\"name\": \"get_weather\", \"arguments\": "'),
    );
    expect(grammar, contains(r'"}\n</tool_call>"'));
    expect(grammar, contains('[^<] .*'));
    expect(grammar, contains(r'("\n" rule'));
    expect(grammar, contains('{0,7}'));
  });

  test('a response schema replaces free text and one call is allowed', () {
    final grammar = toolCallGrammar(
      [_time],
      answer: const Schema.boolean(),
      maxCalls: 1,
    );
    expect(grammar, isNot(contains('[^<] .*')));
    expect(grammar, contains('boolean ::='));
    expect(grammar, startsWith('root ::= rule1 | boolean\n'));
  });

  test('literals escape quotes, backslashes and newlines', () {
    expect(GbnfCompiler.text('a"b\\c\nd'), r'"a\"b\\c\nd"');
  });
}
