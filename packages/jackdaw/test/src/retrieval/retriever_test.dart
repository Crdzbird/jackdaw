import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import 'support/word_embedder.dart';

const _docs = [
  Document(id: 'kestrel', text: 'The kestrel hovers over fields hunting voles'),
  Document(
    id: 'jackdaw',
    text: 'The jackdaw is a clever corvid that caches food',
  ),
  Document(id: 'heron', text: 'A heron wades in rivers and spears fish'),
];

void main() {
  test('retrieves the closest documents with query embeddings', () async {
    final embedder = WordEmbedder();
    final retriever = Retriever(
      embedder: embedder,
      index: FlatVectorIndex(embedder.dimensions),
      batchSize: 2,
    );
    await retriever.add(_docs);
    expect(embedder.calls, [
      (2, EmbeddingKind.document),
      (1, EmbeddingKind.document),
    ]);
    final hits = await retriever.retrieve('which corvid caches food', k: 2);
    expect(hits.first.document.id, 'jackdaw');
    expect(hits.first.score, greaterThan(hits.last.score));
    expect(embedder.calls.last, (1, EmbeddingKind.query));
    expect(await retriever.retrieve('jackdaw', minScore: 0.99), isEmpty);
    expect(retriever.documents.keys, ['kestrel', 'jackdaw', 'heron']);
  });

  test('remove and restore keep texts and vectors in step', () async {
    final embedder = WordEmbedder();
    final index = FlatVectorIndex(embedder.dimensions);
    final first = Retriever(embedder: embedder, index: index);
    await first.add(_docs);
    expect(await first.remove('heron'), isTrue);
    expect(await first.remove('heron'), isFalse);
    final reopened = await decodeFlatIndex(encodeFlatIndex(index));
    final second = Retriever(embedder: embedder, index: reopened)
      ..restore(_docs.take(2));
    final hits = await second.retrieve('kestrel voles', k: 1);
    expect(hits.single.document.id, 'kestrel');
    expect(reopened.length, 2);
  });

  test('an embedder returning the wrong number of vectors fails', () async {
    final embedder = WordEmbedder(brokenAfter: 0);
    final retriever = Retriever(
      embedder: embedder,
      index: FlatVectorIndex(embedder.dimensions),
    );
    await expectLater(retriever.add(_docs), throwsStateError);
  });

  test('the search tool quotes passages as untrusted data', () async {
    final embedder = WordEmbedder();
    final retriever = Retriever(
      embedder: embedder,
      index: FlatVectorIndex(embedder.dimensions),
    );
    await retriever.add(_docs);
    final tool = retrievalTool(retriever, k: 1);
    expect(tool.idempotent, isTrue);
    final result = await tool.invoke(
      const ToolCallPart(
        id: 'c',
        name: 'search_documents',
        arguments: {'query': 'heron fish'},
      ),
    );
    final output = result.output! as Map;
    expect(output['note'], contains('not instructions'));
    final hit = (output['results'] as List).single as Map;
    expect(hit['id'], 'heron');
    expect(hit['text'], contains('spears fish'));
    expect(hit['score'], isA<double>());
  });
}
