import 'dart:typed_data';

import 'package:jackdaw/src/retrieval/normalized.dart';
import 'package:jackdaw/src/retrieval/top_k.dart';
import 'package:jackdaw/src/retrieval/vector_index.dart';
import 'package:jackdaw/src/retrieval/vector_match.dart';

/// An exact [VectorIndex] in pure Dart that compares the query with every
/// stored vector.
///
/// It runs everywhere, including the web, and its results are exact. Search
/// time grows with the number of vectors, so it suits up to some tens of
/// thousands of vectors; `jackdaw_native` provides a faster index.
final class FlatVectorIndex implements VectorIndex {
  /// Creates an empty index for vectors of [dimensions] components.
  factory(int dimensions) = FlatVectorIndex._;

  new _(this.dimensions) : _data = Float32List(dimensions * 16);

  @override
  final int dimensions;

  Float32List _data;
  final List<String> _ids = [];
  final Map<String, int> _rows = {};

  @override
  int get length => _ids.length;

  /// Stored ids in row order.
  List<String> get ids => List.unmodifiable(_ids);

  /// The stored, normalized vector at [row].
  Float32List vectorAt(int row) =>
      Float32List.sublistView(_data, row * dimensions, (row + 1) * dimensions);

  @override
  Future<void> add(Map<String, Float32List> vectors) async {
    for (final MapEntry(key: id, value: vector) in vectors.entries) {
      _check(vector);
      final row = _rows[id] ?? _append(id);
      _data.setAll(row * dimensions, normalized(vector));
    }
  }

  @override
  Future<bool> remove(String id) async {
    final row = _rows.remove(id);
    if (row == null) return false;
    final last = _ids.length - 1;
    final moved = _ids.removeLast();
    if (row != last) {
      _ids[row] = moved;
      _rows[moved] = row;
      _data.setAll(row * dimensions, vectorAt(last));
    }
    return true;
  }

  @override
  Future<List<VectorMatch>> search(Float32List query, {int k = 10}) async {
    _check(query);
    final q = normalized(query);
    final top = TopK(k);
    for (var row = 0; row < _ids.length; row++) {
      var dot = 0.0;
      final base = row * dimensions;
      for (var i = 0; i < dimensions; i++) {
        dot += _data[base + i] * q[i];
      }
      top.offer(_ids[row], dot);
    }
    return top.matches;
  }

  int _append(String id) {
    final row = _ids.length;
    if ((row + 1) * dimensions > _data.length) {
      _data = Float32List(_data.length * 2)..setAll(0, _data);
    }
    _ids.add(id);
    _rows[id] = row;
    return row;
  }

  void _check(Float32List vector) {
    if (vector.length == dimensions) return;
    throw ArgumentError.value(
      vector.length,
      'vector.length',
      'expected $dimensions components',
    );
  }
}
