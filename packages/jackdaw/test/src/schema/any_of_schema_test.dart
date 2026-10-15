import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

List<String> check(Schema schema, Object? value) =>
    schema.validate(value).map((v) => '$v').toList();

void main() {
  const text = Schema.anyOf([
    Schema.string(),
    ObjectSchema(properties: {'@path': Schema.string()}, required: ['@path']),
  ], description: 'Text or a binding');

  test('anyOf serializes its options', () {
    expect(text.toJson(), {
      'description': 'Text or a binding',
      'anyOf': [
        {'type': 'string'},
        {
          'type': 'object',
          'properties': {
            '@path': {'type': 'string'},
          },
          'required': ['@path'],
          'additionalProperties': false,
        },
      ],
    });
  });

  test('a value matching any option is valid', () {
    expect(check(text, 'Hello'), isEmpty);
    expect(check(text, {'@path': '/name'}), isEmpty);
  });

  test('otherwise the closest option explains the problem', () {
    expect(check(text, {'@path': 1}), [r'$.@path expected a string']);
    expect(check(text, 3), [r'$ expected a string']);
    expect(check(const Schema.anyOf([]), 3), [r'$ expected one of no options']);
  });
}
