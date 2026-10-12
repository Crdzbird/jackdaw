import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_anthropic/src/anthropic_request_encoder.dart';
import 'package:test/test.dart';

void main() {
  test('omits optional fields', () {
    final body = encodeMessagesRequest(
      'm',
      const ModelRequest(messages: []),
      defaultMaxTokens: 7,
    );
    expect(body.keys, ['model', 'max_tokens', 'stream', 'messages']);
  });
}
