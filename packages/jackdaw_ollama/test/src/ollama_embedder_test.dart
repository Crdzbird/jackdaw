import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_ollama/jackdaw_ollama.dart';
import 'package:test/test.dart';

void main() {
  test('prefixes texts by kind and reads the vectors', () async {
    final sent = <http.Request>[];
    final embedder = OllamaEmbedder(
      model: 'nomic-embed-text',
      queryPrefix: 'search_query: ',
      documentPrefix: 'search_document: ',
      client: MockClient((request) async {
        sent.add(request);
        final input = (jsonDecode(request.body) as Map)['input'] as List;
        return http.Response(
          jsonEncode({
            'embeddings': [
              for (final _ in input) [1, 2],
            ],
          }),
          200,
        );
      }),
    );
    expect(await embedder.embed(['a', 'b']), hasLength(2));
    await embedder.embed(['q'], kind: EmbeddingKind.query);
    expect('${sent.first.url}', 'http://localhost:11434/api/embed');
    expect(jsonDecode(sent.first.body), {
      'model': 'nomic-embed-text',
      'input': ['search_document: a', 'search_document: b'],
    });
    expect((jsonDecode(sent.last.body) as Map)['input'], ['search_query: q']);
    expect(embedder.id, 'ollama/nomic-embed-text');
  });

  test('no texts means no request and bad answers fail', () async {
    final embedder = OllamaEmbedder(
      model: 'm',
      baseUrl: Uri.parse('http://host:1'),
      client: MockClient((_) async => http.Response('{"embeddings":[]}', 200)),
    );
    expect(await embedder.embed(const []), isEmpty);
    await expectLater(embedder.embed(['a']), throwsFormatException);
  });
}
