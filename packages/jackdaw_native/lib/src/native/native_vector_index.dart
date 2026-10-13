import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/src/ffi/jackdaw_bindings.g.dart';
import 'package:jackdaw_native/src/native/check_status.dart';
import 'package:jackdaw_native/src/native/index_keys.dart';

/// An exact [VectorIndex] in native memory, stored as int8 codes with one
/// scale per vector, which uses a quarter of the memory of floats.
///
/// Search compares the query with every vector using SIMD, which keeps a
/// hundred thousand vectors within a few milliseconds on a phone. Save and
/// reopen it with `saveIndex` and `openIndex`.
final class NativeVectorIndex implements VectorIndex {
  /// Creates an empty index for vectors of [dimensions] components.
  factory(int dimensions) => using((arena) {
    final out = arena<Pointer<jackdaw_index>>();
    checkStatus(jackdaw_index_create(dimensions, out));
    return NativeVectorIndex.adopt(out.value, IndexKeys());
  });

  /// Wraps an existing native [pointer] whose rows map to [keys].
  new adopt(this.pointer, this.keys)
    : dimensions = jackdaw_index_dimensions(pointer);

  /// The native handle; valid until [dispose].
  final Pointer<jackdaw_index> pointer;

  /// Maps document ids to native keys.
  final IndexKeys keys;

  @override
  final int dimensions;

  @override
  int get length => jackdaw_index_size(pointer);

  @override
  Future<void> add(Map<String, Float32List> vectors) async =>
      using<void>((arena) {
        final count = vectors.length;
        final nativeKeys = arena<Uint64>(count);
        final values = arena<Float>(count * dimensions);
        final flat = values.asTypedList(count * dimensions);
        for (final (i, MapEntry(key: id, value: vector))
            in vectors.entries.indexed) {
          if (vector.length != dimensions) {
            throw ArgumentError.value(vector.length, 'vector.length');
          }
          nativeKeys[i] = keys.keyFor(id);
          flat.setAll(i * dimensions, vector);
        }
        checkStatus(jackdaw_index_add(pointer, nativeKeys, values, count));
      });

  @override
  Future<bool> remove(String id) async => using<bool>((arena) {
    final key = keys.release(id);
    if (key == null) return false;
    final removed = arena<Int32>();
    checkStatus(jackdaw_index_remove(pointer, key, removed));
    return removed.value == 1;
  });

  @override
  Future<List<VectorMatch>> search(
    Float32List query, {
    int k = 10,
  }) async => using<List<VectorMatch>>((arena) {
    if (query.length != dimensions) {
      throw ArgumentError.value(query.length, 'query.length');
    }
    final q = arena<Float>(dimensions)
      ..asTypedList(dimensions).setAll(0, query);
    final outKeys = arena<Uint64>(k);
    final scores = arena<Float>(k);
    final count = arena<Int32>();
    checkStatus(jackdaw_index_search(pointer, q, k, outKeys, scores, count));
    return [
      for (var i = 0; i < count.value; i++)
        if (keys.idFor(outKeys[i]) case final id?) VectorMatch(id, scores[i]),
    ];
  });

  /// Frees the native index.
  void dispose() => jackdaw_index_free(pointer);
}
