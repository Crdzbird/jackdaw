import 'dart:convert';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_anthropic/jackdaw_anthropic.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('errors in the stream and in the response fail clearly', () async {
    final overloaded = AnthropicModel(
      model: 'm',
      apiKey: const Secret('k'),
      client: replying(
        sse([
          {
            'type': 'error',
            'error': {'type': 'overloaded_error', 'message': 'Overloaded'},
          },
        ]),
      ),
    );
    await expectLater(
      overloaded.generate(const ModelRequest(messages: [])).toList(),
      throwsA(
        isA<ProviderException>()
            .having((e) => e.statusCode, 'status', 529)
            .having((e) => e.isRetryable, 'retryable', isTrue),
      ),
    );
    final denied = AnthropicModel(
      model: 'm',
      apiKey: const Secret('k'),
      client: replying(
        Stream.value(
          utf8.encode('{"type":"error","error":{"message":"bad key"}}'),
        ),
        status: 401,
      ),
    );
    await expectLater(
      denied.generate(const ModelRequest(messages: [])).toList(),
      throwsA(
        isA<ProviderException>().having((e) => e.message, 'm', 'bad key'),
      ),
    );
  });
}
