import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_gemini/jackdaw_gemini.dart';
import 'package:test/test.dart';

MockClient _answer(Object? json, {void Function(http.Request)? seen}) =>
    MockClient((request) async {
      seen?.call(request);
      return http.Response(jsonEncode(json), 200);
    });

void main() {
  test('sends task types and reads the vectors', () async {
    final sent = <http.Request>[];
    final embedder = GeminiEmbedder(
      model: 'gemini-embedding-001',
      apiKey: const Secret('key'),
      dimensions: 2,
      client: _answer({
        'embeddings': [
          {
            'values': [0.5, 0.5],
          },
        ],
      }, seen: sent.add),
    );
    expect(await embedder.embed(['doc']), [
      [0.5, 0.5],
    ]);
    await embedder.embed(['q'], kind: EmbeddingKind.query);
    expect(
      '${sent.first.url}',
      'https://generativelanguage.googleapis.com/v1beta/models/'
          'gemini-embedding-001:batchEmbedContents',
    );
    expect(sent.first.headers['x-goog-api-key'], 'key');
    final first = (jsonDecode(sent.first.body) as Map)['requests'] as List;
    expect(first.single, {
      'model': 'models/gemini-embedding-001',
      'content': {
        'parts': [
          {'text': 'doc'},
        ],
      },
      'taskType': 'RETRIEVAL_DOCUMENT',
      'outputDimensionality': 2,
    });
    final second = (jsonDecode(sent.last.body) as Map)['requests'] as List;
    expect((second.single as Map)['taskType'], 'RETRIEVAL_QUERY');
    expect(embedder.id, 'gemini/gemini-embedding-001');
  });

  test('no texts means no request and bad answers fail', () async {
    final embedder = GeminiEmbedder(
      model: 'm',
      apiKey: const Secret('k'),
      baseUrl: Uri.parse('http://localhost:9/v1beta'),
      client: _answer({'embeddings': <Object?>[]}),
    );
    expect(await embedder.embed(const []), isEmpty);
    await expectLater(embedder.embed(['a']), throwsFormatException);
  });
}
