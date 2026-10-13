import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_cli/src/schema_file.dart';

/// `jackdaw validate <schema.json> <value.json>`: checks a JSON value
/// against a schema the way tool arguments and structured output are
/// checked, and lists every violation.
Future<int> validateCommand(List<String> args, StringSink out) async {
  if (args.length != 2) {
    out.writeln('usage: jackdaw validate <schema.json> <value.json>');
    return 64;
  }
  final schema = readJsonFile(args.first, out);
  if (schema is! Map<String, Object?>) {
    if (schema != null) out.writeln('the schema must be a JSON object');
    return 65;
  }
  final value = readJsonFile(args.last, out);
  if (value == null) return 65;
  final violations = schemaFromJson(schema).validate(value);
  out.writeln(
    [
      ...violations,
      if (violations.isEmpty) 'valid',
      if (violations.isNotEmpty) '${violations.length} violations',
    ].join('\n'),
  );
  return violations.isEmpty ? 0 : 1;
}
