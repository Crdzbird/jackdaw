import 'dart:io';

import 'package:jackdaw_mcp/io.dart';
import 'package:jackdaw_mcp/jackdaw_mcp.dart';

/// Lists the tools of a local MCP server given on the command line, for
/// example `dart run example/main.dart npx -y @modelcontextprotocol/server-everything`.
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('usage: main.dart <server command> [arguments]');
    exitCode = 64;
    return;
  }
  final transport = await startStdioServer(args.first, args.skip(1).toList());
  final session = await McpClient.connect(transport, name: 'local');
  for (final tool in await mcpTools(session)) {
    stdout.writeln('${tool.name}: ${tool.description}');
  }
  await session.close();
}
