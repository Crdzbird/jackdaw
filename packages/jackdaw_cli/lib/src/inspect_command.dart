import 'dart:io';

import 'package:jackdaw/io.dart';
import 'package:jackdaw_cli/src/describe_record.dart';
import 'package:jackdaw_cli/src/journal_summary.dart';

/// `jackdaw inspect <session.jsonl>`: prints a session journal as a
/// numbered timeline and what the session is waiting for.
Future<int> inspectCommand(List<String> args, StringSink out) async {
  if (args.length != 1 || !args.single.endsWith('.jsonl')) {
    out.writeln('usage: jackdaw inspect <session.jsonl>');
    return 64;
  }
  final file = File(args.single);
  if (!file.existsSync()) {
    out.writeln('no such file: ${file.path}');
    return 66;
  }
  final name = file.uri.pathSegments.last;
  final id = name.substring(0, name.length - '.jsonl'.length);
  final records = await FileSessionStore(file.parent).load(id);
  for (final (index, record) in records.indexed) {
    final lines = describeRecord(record).split('\n');
    for (final line in lines) {
      out.writeln('${'${index + 1}'.padLeft(4)}  $line');
    }
  }
  out.writeln(journalSummary(records));
  return 0;
}
