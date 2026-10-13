import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:jackdaw_native/src/ffi/jackdaw_bindings.g.dart';
import 'package:jackdaw_native/src/native/check_status.dart';
import 'package:jackdaw_native/src/native/index_keys.dart';
import 'package:jackdaw_native/src/native/native_vector_index.dart';

/// Saves [index] to [path] and its ids to `<path>.ids.json`, replacing
/// each file atomically, on a background isolate. Do not change the index
/// until the returned future completes.
Future<void> saveIndex(NativeVectorIndex index, String path) async {
  final ids = jsonEncode(index.keys.toJson());
  final address = index.pointer.address;
  await Isolate.run(() {
    using((arena) {
      final nativePath = path.toNativeUtf8(allocator: arena).cast<Char>();
      checkStatus(jackdaw_index_save(Pointer.fromAddress(address), nativePath));
    });
    File('$path.ids.json.tmp')
      ..writeAsStringSync(ids, flush: true)
      ..renameSync('$path.ids.json');
  });
}

/// Opens an index written by [saveIndex] on a background isolate. Files
/// that do not belong together fail with [FormatException].
Future<NativeVectorIndex> openIndex(String path) async {
  final (address, ids) = await Isolate.run(() {
    final text = File('$path.ids.json').readAsStringSync();
    return using((arena) {
      final out = arena<Pointer<jackdaw_index>>();
      final nativePath = path.toNativeUtf8(allocator: arena).cast<Char>();
      checkStatus(jackdaw_index_load(nativePath, out));
      return (out.value.address, text);
    });
  });
  final keys = IndexKeys.fromJson(jsonDecode(ids) as Map<String, Object?>);
  final index = NativeVectorIndex.adopt(Pointer.fromAddress(address), keys);
  if (index.length != keys.length) {
    index.dispose();
    throw FormatException('$path and its ids file do not match');
  }
  return index;
}
