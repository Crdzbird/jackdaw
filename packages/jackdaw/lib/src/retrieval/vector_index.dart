import 'dart:typed_data';

import 'package:jackdaw/src/retrieval/vector_match.dart';

/// Stores vectors by id and finds the ones closest to a query.
///
/// Vectors are compared by cosine similarity. Every vector must have
/// [dimensions] components; others fail with [ArgumentError].
abstract interface class VectorIndex {
  /// Number of components in every vector.
  int get dimensions;

  /// Number of stored vectors.
  int get length;

  /// Stores [vectors], replacing any stored under the same id.
  Future<void> add(Map<String, Float32List> vectors);

  /// Removes the vector stored under [id]; returns whether one existed.
  Future<bool> remove(String id);

  /// Returns up to [k] ids closest to [query], closest first.
  Future<List<VectorMatch>> search(Float32List query, {int k});
}
