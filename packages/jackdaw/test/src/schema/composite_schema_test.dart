import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

List<String> check(Schema schema, Object? value) =>
    schema.validate(value).map((v) => '$v').toList();

void main() {
  const city = Schema.object(
    properties: {
      'name': Schema.string(),
      'tags': Schema.array(items: Schema.string()),
    },
    required: ['name'],
  );

  test('object schema serializes properties', () {
    expect(city.toJson(), {
      'type': 'object',
      'properties': {
        'name': {'type': 'string'},
        'tags': {
          'type': 'array',
          'items': {'type': 'string'},
        },
      },
      'required': ['name'],
      'additionalProperties': false,
    });
  });

  test('object schema accepts valid values', () {
    expect(
      check(city, {
        'name': 'Lima',
        'tags': ['coast'],
      }),
      isEmpty,
    );
  });

  test('object schema reports every problem with a path', () {
    expect(
      check(city, {
        'tags': ['ok', 2],
        'extra': true,
      }),
      [
        r'$.name is required',
        r'$.extra is not allowed',
        r'$.tags[1] expected a string',
      ],
    );
    expect(check(city, 'Lima'), [r'$ expected an object']);
    expect(check(city, {1: 'x'}), [r'$ expected an object']);
    expect(check(city, {'name': 'x', 'tags': 'y'}), [
      r'$.tags expected an array',
    ]);
  });

  test('additional properties can be allowed', () {
    const open = Schema.object(properties: {}, additionalProperties: true);
    expect(check(open, {'any': 1}), isEmpty);
  });
}
