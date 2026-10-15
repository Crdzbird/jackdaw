import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

List<String> check(Schema schema, Object? value) =>
    schema.validate(value).map((v) => '$v').toList();

void main() {
  const shape = Schema.union(
    discriminator: 'component',
    variants: {
      'Text': ObjectSchema(
        properties: {'text': Schema.string()},
        required: ['text'],
      ),
      'Divider': ObjectSchema(
        properties: {'component': Schema.integer()},
        required: ['component'],
      ),
    },
    description: 'A component',
  );

  test('a union serializes as anyOf with one-value enum tags', () {
    expect(shape.toJson(), {
      'description': 'A component',
      'anyOf': [
        {
          'type': 'object',
          'properties': {
            'component': {
              'type': 'string',
              'enum': ['Text'],
            },
            'text': {'type': 'string'},
          },
          'required': ['component', 'text'],
          'additionalProperties': false,
        },
        {
          'type': 'object',
          'properties': {
            'component': {
              'type': 'string',
              'enum': ['Divider'],
            },
          },
          'required': ['component'],
          'additionalProperties': false,
        },
      ],
    });
  });

  test('a value is checked against the variant its tag names', () {
    expect(check(shape, {'component': 'Text', 'text': 'Hi'}), isEmpty);
    expect(check(shape, {'component': 'Divider'}), isEmpty);
    expect(check(shape, {'component': 'Text'}), [r'$.text is required']);
    expect(check(shape, {'component': 'Divider', 'text': 'x'}), [
      r'$.text is not allowed',
    ]);
    expect(check(shape, {'component': 'Card'}), [
      r'$.component expected one of Text, Divider',
    ]);
    expect(check(shape, {'component': 1}), hasLength(1));
    expect(check(shape, <String, Object?>{}), hasLength(1));
    expect(check(shape, 'Text'), [r'$ expected an object']);
  });

  test('a tagged anyOf reads back as the same union', () {
    final read = schemaFromJson(shape.toJson());
    expect(read, isA<UnionSchema>());
    expect(read.toJson(), shape.toJson());
    expect((read as UnionSchema).discriminator, 'component');
    expect(read.variants.keys, ['Text', 'Divider']);
  });
}
