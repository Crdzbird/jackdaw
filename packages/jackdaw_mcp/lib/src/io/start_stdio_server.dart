import 'dart:convert';
import 'dart:io';

import 'package:jackdaw_mcp/src/mcp_transport.dart';
import 'package:jackdaw_mcp/src/stream_mcp_transport.dart';

const List<String> _kept = ['PATH', 'HOME', 'SystemRoot', 'TEMP', 'TMPDIR'];

/// Starts the MCP server [executable] with [arguments] and talks to it over
/// its stdin and stdout.
///
/// The server does not inherit this process's environment unless
/// [inheritEnvironment] is true, so API keys in it do not reach the
/// server; only `PATH`, `HOME` and temp-folder variables pass, plus
/// [environment]. The server's stderr is passed to [onStderr] when given.
/// Closing the transport ends the process.
Future<McpTransport> startStdioServer(
  String executable,
  List<String> arguments, {
  Map<String, String> environment = const {},
  bool inheritEnvironment = false,
  String? workingDirectory,
  void Function(String line)? onStderr,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    includeParentEnvironment: inheritEnvironment,
    environment: {
      for (final name in _kept) name: ?Platform.environment[name],
      ...environment,
    },
  );
  final stderrDone = process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach(onStderr ?? (_) {});
  return StreamMcpTransport(
    process.stdout.transform(utf8.decoder).transform(const LineSplitter()),
    process.stdin.writeln,
    onClose: () async {
      await process.stdin.close().then((_) {}, onError: (Object _) {});
      process.kill();
      await process.exitCode;
      await stderrDone;
    },
  );
}
