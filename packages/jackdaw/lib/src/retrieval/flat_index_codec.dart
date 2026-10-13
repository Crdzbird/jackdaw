import 'dart:convert';
import 'dart:typed_data';

import 'package:jackdaw/src/retrieval/flat_vector_index.dart';

const _magic = 0x4944564a;
const _version = 1;

/// Serializes [index] to bytes that [decodeFlatIndex] reads back.
///
/// The layout is a 16 byte header (magic, version, dimensions, count as
/// little-endian 32 bit integers), the vectors as 32 bit floats, then the
/// ids as a JSON list.
Uint8List encodeFlatIndex(FlatVectorIndex index) {
  final ids = utf8.encode(jsonEncode(index.ids));
  final vectorBytes = index.length * index.dimensions * 4;
  final bytes = ByteData(16 + vectorBytes + ids.length)
    ..setUint32(0, _magic, Endian.little)
    ..setUint32(4, _version, Endian.little)
    ..setUint32(8, index.dimensions, Endian.little)
    ..setUint32(12, index.length, Endian.little);
  var at = 16;
  for (var row = 0; row < index.length; row++) {
    for (final x in index.vectorAt(row)) {
      bytes.setFloat32(at, x, Endian.little);
      at += 4;
    }
  }
  return bytes.buffer.asUint8List()..setAll(at, ids);
}

/// Reads an index written by [encodeFlatIndex]; damaged or foreign data
/// fails with [FormatException].
Future<FlatVectorIndex> decodeFlatIndex(Uint8List data) async {
  final bytes = ByteData.sublistView(data);
  if (data.length < 16 ||
      bytes.getUint32(0, Endian.little) != _magic ||
      bytes.getUint32(4, Endian.little) != _version) {
    throw const FormatException('not a jackdaw vector index');
  }
  final dimensions = bytes.getUint32(8, Endian.little);
  final count = bytes.getUint32(12, Endian.little);
  final idsAt = 16 + count * dimensions * 4;
  if (idsAt > data.length) throw const FormatException('index is truncated');
  final ids = (jsonDecode(utf8.decode(data.sublist(idsAt))) as List)
      .cast<String>();
  if (ids.length != count) throw const FormatException('id count mismatch');
  final index = FlatVectorIndex(dimensions);
  for (var row = 0; row < count; row++) {
    final vector = Float32List(dimensions);
    for (var i = 0; i < dimensions; i++) {
      vector[i] = bytes.getFloat32(
        16 + (row * dimensions + i) * 4,
        Endian.little,
      );
    }
    await index.add({ids[row]: vector});
  }
  return index;
}
