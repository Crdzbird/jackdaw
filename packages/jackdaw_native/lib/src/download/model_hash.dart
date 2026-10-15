import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:jackdaw_native/src/download/model_file.dart';

/// The SHA-256 of the file at [path] in lower-case hex, computed on
/// another isolate so a large file does not stall the caller.
Future<String> modelHash(String path) => Isolate.run(
  () async => '${await sha256.bind(File(path).openRead()).first}',
);

/// Whether [file] is [model] as already checked: the right size, with a
/// marker beside it holding the expected SHA-256.
bool modelChecked(File file, ModelFile model) {
  final mark = File('${file.path}.sha256');
  return file.existsSync() &&
      file.lengthSync() == model.bytes &&
      mark.existsSync() &&
      mark.readAsStringSync() == model.sha256;
}
