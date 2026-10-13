import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  test('plain documents become typed schemas', () {
    final schema = schemaFromJson({
      'type': 'object',
      'title': 'Args',
      'description': 'Arguments',
      'properties': {
        'city': {'type': 'string', 'description': 'City'},
        'unit': {
          'type': 'string',
          'enum': ['c', 'f'],
        },
        'days': {'type': 'integer'},
        'ratio': {'type': 'number'},
        'alerts': {'type': 'boolean'},
        'tags': {
          'type': 'array',
          'items': {'type': 'string'},
        },
      },
      'required': ['city'],
    });
    expect(schema, isA<ObjectSchema>());
    final object = schema as ObjectSchema;
    expect(object.additionalProperties, isTrue);
    expect(object.required, ['city']);
    expect(object.description, 'Arguments');
    expect(object.properties['city'], isA<StringSchema>());
    expect((object.properties['unit']! as StringSchema).enumValues, ['c', 'f']);
    expect(object.properties['days'], isA<IntegerSchema>());
    expect(object.properties['ratio'], isA<NumberSchema>());
    expect(object.properties['alerts'], isA<BooleanSchema>());
    expect(
      (object.properties['tags']! as ArraySchema).items,
      isA<StringSchema>(),
    );
    expect(object.validate({'city': 'Lima', 'extra': 1}), isEmpty);
    expect(object.validate({'days': 1}), isNotEmpty);
  });

  test('unknown keywords keep the whole document', () {
    const nullable = {
      'anyOf': [
        {'type': 'string'},
        {'type': 'null'},
      ],
    };
    for (final json in <Map<String, Object?>>[
      nullable,
      {'type': 'string', 'minLength': 2},
      {'type': 'string', 'description': 3},
      {
        'type': 'string',
        'enum': [1, 2],
      },
      {'type': 'array', 'items': true},
      {'type': 'object', 'additionalProperties': <String, Object?>{}},
      {'type': 'object', 'properties': 'x'},
      {
        'type': 'object',
        'required': [1],
      },
      {
        'type': ['string', 'null'],
      },
    ]) {
      final schema = schemaFromJson(json);
      expect(schema, isA<RawSchema>(), reason: '$json');
      expect(schema.toJson(), same(json));
      expect(schema.validate(42), isEmpty);
    }
    final object = schemaFromJson({
      'type': 'object',
      'properties': {'name': nullable},
      'additionalProperties': false,
    }) as ObjectSchema;
    expect(object.properties['name'], isA<RawSchema>());
    expect(object.additionalProperties, isFalse);
  });

  test('tool inputs are always objects', () {
    expect(toolInputFromJson({'type': 'object'}).additionalProperties, isTrue);
    final fallback = toolInputFromJson({
      r'$defs': <String, Object?>{},
      'type': 'object',
      'description': 'Uses refs',
    });
    expect(fallback.description, 'Uses refs');
    expect(fallback.properties, isEmpty);
    expect(fallback.additionalProperties, isTrue);
    expect(toolInputFromJson({'anyOf': <Object?>[]}).description, isNull);
  });
}
