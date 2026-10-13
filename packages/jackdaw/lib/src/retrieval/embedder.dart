import 'dart:typed_data';

import 'package:jackdaw/src/retrieval/embedding_kind.dart';

/// Turns texts into vectors whose closeness reflects closeness in meaning.
abstract interface class Embedder {
  /// Stable identifier such as `openai/text-embedding-3-small`.
  String get id;

  /// Embeds [texts] in order, one vector per text.
  Future<List<Float32List>> embed(
    List<String> texts, {
    EmbeddingKind kind = EmbeddingKind.document,
  });
}
