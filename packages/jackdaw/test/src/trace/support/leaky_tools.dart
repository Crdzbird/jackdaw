import 'package:jackdaw/jackdaw.dart';

/// An AWS-shaped access key, built at runtime so scanners do not flag it.
final String fakeAwsKey = ['AKIA', 'ABCDEFGHIJKLMNOP'].join();

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
      'aws': fakeAwsKey,
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
