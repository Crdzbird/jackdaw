import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  test('an anyOf without a shared one-value tag is untagged', () {
    Map<String, Object?> tagged(String key, Object tag) => {
      'type': 'object',
      'properties': {
        key: {'type': 'string', 'enum': tag},
      },
      'required': [key],
    };
    for (final json in <Map<String, Object?>>[
      {'anyOf': <Object?>[]},
      {'anyOf': 'x'},
      {
        'anyOf': [
          tagged('kind', ['a']),
          'x',
        ],
      },
      {
        'anyOf': [
          {'type': 'string'},
          {'type': 'null'},
        ],
      },
    ]) {
      expect(schemaFromJson(json), isA<RawSchema>(), reason: '$json');
    }
    for (final json in <Map<String, Object?>>[
      {
        'anyOf': [
          tagged('kind', ['a']),
          tagged('type', ['b']),
        ],
      },
      {
        'anyOf': [
          tagged('kind', ['a']),
          tagged('kind', ['a']),
        ],
      },
      {
        'anyOf': [
          tagged('kind', ['a', 'b']),
        ],
      },
      {
        'anyOf': [
          tagged('kind', ['a']),
          {'type': 'string'},
        ],
      },
      {
        'anyOf': [
          {
            'type': 'object',
            'properties': {
              'kind': {
                'type': 'string',
                'enum': ['a'],
              },
            },
          },
        ],
      },
    ]) {
      final schema = schemaFromJson(json);
      expect(schema, isA<AnyOfSchema>(), reason: '$json');
      expect(
        (schema as AnyOfSchema).options,
        hasLength((json['anyOf']! as List).length),
      );
    }
  });
}
