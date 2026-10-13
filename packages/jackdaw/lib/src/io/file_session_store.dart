import 'dart:convert';
import 'dart:io';

import 'package:jackdaw/src/session/record_codec.dart';
import 'package:jackdaw/src/session/session_record.dart';
import 'package:jackdaw/src/session/session_store.dart';

/// A [SessionStore] that keeps each journal in a JSON Lines file.
///
/// Every append is flushed before it completes. A torn last line, left by a
/// process killed mid-write, is ignored; damage on earlier lines is reported.
/// Keep [directory] inside the app's private storage: journals contain the
/// full conversation and tool results.
final class FileSessionStore implements SessionStore {
  /// Creates a store writing into [directory].
  factory(Directory directory) = FileSessionStore._;

  new _(this.directory);

  /// Folder holding one `<sessionId>.jsonl` file per session.
  final Directory directory;

  static final RegExp _validId = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  @override
  Future<List<SessionRecord>> load(String sessionId) async {
    final file = _file(sessionId);
    if (!file.existsSync()) return const [];
    final lines = (await file.readAsLines()).where((l) => l.isNotEmpty);
    final records = <SessionRecord>[];
    for (final (index, line) in lines.indexed) {
      final record = _decode(line);
      if (record == null && index < lines.length - 1) {
        throw FormatException('corrupt journal line ${index + 1}', file.path);
      }
      if (record != null) records.add(record);
    }
    return records;
  }

  @override
  Future<void> append(String sessionId, SessionRecord record) async {
    final file = _file(sessionId);
    await directory.create(recursive: true);
    final sink = await file.open(mode: FileMode.append);
    try {
      await sink.writeString('${jsonEncode(recordToJson(record))}\n');
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  File _file(String sessionId) {
    if (!_validId.hasMatch(sessionId)) {
      throw ArgumentError.value(sessionId, 'sessionId', 'use [A-Za-z0-9_-]');
    }
    return File('${directory.path}/$sessionId.jsonl');
  }

  static SessionRecord? _decode(String line) {
    try {
      return recordFromJson(jsonDecode(line) as Map<String, Object?>);
    } on FormatException {
      return null;
    }
  }
}
