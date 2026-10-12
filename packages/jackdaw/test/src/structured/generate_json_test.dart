import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_test/jackdaw_test.dart';
import 'package:test/test.dart';

const schema = ObjectSchema(
  properties: {'n': Schema.integer()},
  required: ['n'],
);

void main() {
  test('returns validated JSON and sends the schema', () async {
    final model = ScriptedModel([
      textTurn(['{"n":', ' 3}']),
    ]);
    final value = await generateJson(model, [Message.user('n?')], schema);
    expect(value, {'n': 3});
    expect(model.requests.single.responseSchema, same(schema));
  });

  test('rejects text that is not JSON', () {
    final model = ScriptedModel([
      textTurn(['sure! ']),
    ]);
    expect(
      generateJson(model, const [], schema),
      throwsA(
        isA<StructuredOutputException>()
            .having((e) => e.text, 'text', 'sure! ')
            .having((e) => '$e', 'message', contains('not valid JSON')),
      ),
    );
  });

  test('rejects JSON that breaks the schema', () {
    final model = ScriptedModel([
      textTurn(['{"n": "x"}']),
    ]);
    expect(
      generateJson(model, const [], schema),
      throwsA(
        isA<StructuredOutputException>().having(
          (e) => '$e',
          'message',
          r'StructuredOutputException: $.n expected an integer',
        ),
      ),
    );
  });
}
