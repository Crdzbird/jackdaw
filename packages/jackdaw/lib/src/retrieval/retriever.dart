import 'dart:math' as math;

import 'package:jackdaw/src/retrieval/document.dart';
import 'package:jackdaw/src/retrieval/embedder.dart';
import 'package:jackdaw/src/retrieval/embedding_kind.dart';
import 'package:jackdaw/src/retrieval/retrieved_document.dart';
import 'package:jackdaw/src/retrieval/vector_index.dart';

/// Finds the stored documents closest in meaning to a query.
///
/// Documents are embedded with [embedder] in batches of [batchSize] and
/// their vectors kept in [index]; the texts stay in memory. After reopening
/// a saved index, hand the texts back with [restore].
final class Retriever {
  /// Creates a retriever over [index].
  factory({
    required Embedder embedder,
    required VectorIndex index,
    int batchSize,
  }) = Retriever._;

  new _({required this.embedder, required this.index, this.batchSize = 32});

  /// Turns texts and queries into vectors.
  final Embedder embedder;

  /// Holds one vector per document.
  final VectorIndex index;

  /// Texts per embedding request.
  final int batchSize;

  final Map<String, Document> _documents = {};

  /// Documents known to the retriever, by id.
  Map<String, Document> get documents => Map.unmodifiable(_documents);

  /// Embeds and stores [documents], replacing any with the same id.
  Future<void> add(List<Document> documents) async {
    for (var at = 0; at < documents.length; at += batchSize) {
      final end = math.min(at + batchSize, documents.length);
      final batch = documents.sublist(at, end);
      final vectors = await embedder.embed([for (final d in batch) d.text]);
      if (vectors.length != batch.length) {
        throw StateError(
          '${embedder.id} returned ${vectors.length} vectors '
          'for ${batch.length} texts',
        );
      }
      await index.add({for (final (i, d) in batch.indexed) d.id: vectors[i]});
      for (final d in batch) {
        _documents[d.id] = d;
      }
    }
  }

  /// Makes already indexed [documents] retrievable without embedding them.
  void restore(Iterable<Document> documents) {
    for (final d in documents) {
      _documents[d.id] = d;
    }
  }

  /// Removes the document [id]; returns whether the index held it.
  Future<bool> remove(String id) async {
    _documents.remove(id);
    return await index.remove(id);
  }

  /// Returns up to [k] documents closest to [query], closest first,
  /// skipping any whose score is below [minScore].
  Future<List<RetrievedDocument>> retrieve(
    String query, {
    int k = 4,
    double minScore = -1,
  }) async {
    final vectors = await embedder.embed([query], kind: EmbeddingKind.query);
    final matches = await index.search(vectors.single, k: k);
    return [
      for (final match in matches)
        if (_documents[match.id] case final document?
            when match.score >= minScore)
          RetrievedDocument(document, match.score),
    ];
  }
}
