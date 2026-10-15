import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  test('an anyOf without a shared one-value tag stays raw', () {
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
      expect(schemaFromJson(json), isA<RawSchema>(), reason: '$json');
    }
  });
}
