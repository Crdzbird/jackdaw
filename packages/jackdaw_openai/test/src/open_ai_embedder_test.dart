import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_openai/jackdaw_openai.dart';
import 'package:test/test.dart';

MockClient _answer(Object? json, {void Function(http.Request)? seen}) =>
    MockClient((request) async {
      seen?.call(request);
      return http.Response(jsonEncode(json), 200);
    });

void main() {
  test('embeds in input order and sends the documented body', () async {
    late http.Request sent;
    final embedder = OpenAiEmbedder(
      model: 'text-embedding-3-small',
      apiKey: const Secret('sk-test'),
      baseUrl: Uri.parse('http://localhost:1234/v1'),
      dimensions: 2,
      client: _answer({
        'data': [
          {
            'index': 1,
            'embedding': [0, 1],
          },
          {
            'index': 0,
            'embedding': [1, 0],
          },
        ],
      }, seen: (r) => sent = r),
    );
    final vectors = await embedder.embed(['a', 'b']);
    expect(vectors, [
      [1, 0],
      [0, 1],
    ]);
    expect('${sent.url}', 'http://localhost:1234/v1/embeddings');
    expect(sent.headers['authorization'], 'Bearer sk-test');
    expect(jsonDecode(sent.body), {
      'model': 'text-embedding-3-small',
      'input': ['a', 'b'],
      'encoding_format': 'float',
      'dimensions': 2,
    });
    expect(embedder.id, 'openai/text-embedding-3-small');
  });

  test('no texts means no request and bad answers fail', () async {
    var calls = 0;
    final empty = OpenAiEmbedder(
      model: 'm',
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
    );
    expect(await empty.embed(const []), isEmpty);
    expect(calls, 0);
    await expectLater(empty.embed(['a']), throwsFormatException);
    final wrong = OpenAiEmbedder(
      model: 'm',
      client: _answer({'data': <Object?>[]}),
    );
    await expectLater(wrong.embed(['a']), throwsFormatException);
  });

  test('errors become ProviderException', () async {
    final embedder = OpenAiEmbedder(
      model: 'm',
      client: MockClient(
        (_) async => http.Response('{"error":{"message":"nope"}}', 401),
      ),
    );
    await expectLater(
      embedder.embed(['a']),
      throwsA(
        isA<ProviderException>().having((e) => e.statusCode, 'status', 401),
      ),
    );
  });
}
