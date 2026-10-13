import 'dart:convert';
import 'dart:io';

/// Reads the JSON document at [path], or returns `null` after explaining
/// the problem on [out].
Object? readJsonFile(String path, StringSink out) {
  final file = File(path);
  if (!file.existsSync()) {
    out.writeln('no such file: $path');
    return null;
  }
  try {
    return jsonDecode(file.readAsStringSync());
  } on FormatException catch (error) {
    out.writeln('$path is not JSON: ${error.message}');
    return null;
  }
}
