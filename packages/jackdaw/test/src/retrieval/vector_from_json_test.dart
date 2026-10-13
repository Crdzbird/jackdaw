import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  test('vectors are read only from lists of numbers', () {
    expect(vectorFromJson([1, 2.5]), [1, 2.5]);
    expect(() => vectorFromJson('x'), throwsFormatException);
    expect(() => vectorFromJson([1, 'a']), throwsFormatException);
  });

  test('endpoints resolve under the root with or without a slash', () {
    expect(
      '${resolveEndpoint(Uri.parse('http://h/v1'), 'embeddings')}',
      'http://h/v1/embeddings',
    );
    expect(
      '${resolveEndpoint(Uri.parse('http://h/v1/'), 'embeddings')}',
      'http://h/v1/embeddings',
    );
  });

  test('postForJson decodes the answer', () async {
    final transport = HttpTransport(
      provider: 'p',
      client: MockClient((request) async => http.Response('{"a":[1]}', 200)),
    );
    final json = await transport.postForJson(
      Uri.parse('http://h/x'),
      headers: const {},
      body: const {'q': 1},
    );
    expect(json, {
      'a': [1],
    });
  });
}
