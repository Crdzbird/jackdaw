import 'dart:typed_data';

import 'package:jackdaw/jackdaw.dart';

/// Embeds text as counts of hashed lowercase words, so texts that share
/// words are close. Records every call for assertions.
final class WordEmbedder implements Embedder {
  factory({int dimensions, int? brokenAfter}) = WordEmbedder._;

  new _({this.dimensions = 64, this.brokenAfter});

  final int dimensions;
  final int? brokenAfter;
  final List<(int, EmbeddingKind)> calls = [];

  @override
  String get id => 'test/words';

  @override
  Future<List<Float32List>> embed(
    List<String> texts, {
    EmbeddingKind kind = EmbeddingKind.document,
  }) async {
    calls.add((texts.length, kind));
    final vectors = [for (final text in texts) _vector(text.toLowerCase())];
    if (brokenAfter case final n? when calls.length > n) {
      return vectors.skip(1).toList();
    }
    return vectors;
  }

  Float32List _vector(String text) {
    final vector = Float32List(dimensions);
    for (final word in text.split(RegExp('[^a-z0-9]+'))) {
      if (word.isEmpty) continue;
      var hash = 2166136261;
      for (final unit in word.codeUnits) {
        hash = ((hash ^ unit) * 16777619) & 0xffffffff;
      }
      vector[hash % dimensions] += 1;
    }
    return vector;
  }
}
