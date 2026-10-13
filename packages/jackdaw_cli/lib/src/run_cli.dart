import 'package:jackdaw_cli/src/grammar_command.dart';
import 'package:jackdaw_cli/src/inspect_command.dart';
import 'package:jackdaw_cli/src/trace_command.dart';
import 'package:jackdaw_cli/src/validate_command.dart';

const String _usage = '''
usage: jackdaw <command> [arguments]

  inspect <session.jsonl>             timeline of a session journal
  trace <trace.jsonl>                 spans written by a JsonlTracer
  grammar <schema.json>               GBNF grammar for a JSON Schema
  validate <schema.json> <value.json> check a value against a schema''';

/// Runs the command line [args], writing to [out], and returns the exit
/// code: 0 on success, 1 for invalid values, 64 and above for usage and
/// input errors.
Future<int> runCli(List<String> args, StringSink out) async {
  final command = args.isEmpty ? '' : args.first;
  final rest = args.skip(1).toList();
  return await switch (command) {
    'inspect' => inspectCommand(rest, out),
    'trace' => traceCommand(rest, out),
    'grammar' => grammarCommand(rest, out),
    'validate' => validateCommand(rest, out),
    _ => _help(out, known: command.isEmpty || command == 'help'),
  };
}

Future<int> _help(StringSink out, {required bool known}) async {
  out.writeln(_usage);
  return known ? 0 : 64;
}
