import 'package:jackdaw/jackdaw.dart';

const _anything = ObjectSchema(properties: {}, additionalProperties: true);

/// A tool that returns [secret] and an unregistered access key, and one
/// that throws an error mentioning [secret].
List<Tool<Object?>> leakyTools(String secret) => [
  Tool<Object?>(
    name: 'lookup',
    description: 'lookup',
    input: _anything,
    decode: (json) => json,
    run: (input) => {
      'value': secret,
      'aws': 'AKIAABCDEFGHIJKLMNOP',
      'nested': [
        {'auth': 'Bearer abcdefghijklmnopqrstuvwxyz'},
      ],
    },
  ),
  Tool<Object?>(
    name: 'explode',
    description: 'explode',
    input: _anything,
    decode: (json) => json,
    run: (input) => throw StateError('cannot use $secret'),
  ),
];
