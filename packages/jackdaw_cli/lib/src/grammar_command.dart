import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_cli/src/schema_file.dart';

/// `jackdaw grammar <schema.json>`: prints the GBNF grammar that constrains
/// local models to JSON matching the schema.
Future<int> grammarCommand(List<String> args, StringSink out) async {
  if (args.length != 1) {
    out.writeln('usage: jackdaw grammar <schema.json>');
    return 64;
  }
  final json = readJsonFile(args.single, out);
  if (json is! Map<String, Object?>) {
    if (json != null) out.writeln('the schema must be a JSON object');
    return 65;
  }
  out.writeln(GbnfCompiler().compile(schemaFromJson(json)));
  return 0;
}
