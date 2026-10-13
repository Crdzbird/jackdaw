import 'dart:math' as math;

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_mcp/src/mcp_output.dart';
import 'package:jackdaw_mcp/src/mcp_session.dart';

final RegExp _unsafe = RegExp('[^A-Za-z0-9_-]');

/// Turns every tool of [session] into a jackdaw [Tool], treating the server
/// as untrusted.
///
/// Names become `<prefix>_<name>` with unsafe characters replaced, so a
/// server cannot shadow another server's or the app's tools; a clash fails
/// with [StateError]. Every call needs approval unless [requireApproval] is
/// false, descriptions are cut to [maxDescriptionChars] and labelled with
/// the server, and results are marked as data and cut to [maxOutputChars].
/// Calls are never retried after an interruption.
Future<List<Tool<Object?>>> mcpTools(
  McpSession session, {
  String? prefix,
  bool requireApproval = true,
  int maxDescriptionChars = 1024,
  int maxOutputChars = 32000,
  Duration timeout = const Duration(minutes: 1),
}) async {
  final head = (prefix ?? session.name).replaceAll(_unsafe, '_');
  final tools = <String, Tool<Object?>>{};
  for (final raw in await session.listTools()) {
    if (raw['name'] case final String remote) {
      final full = '${head}_${remote.replaceAll(_unsafe, '_')}';
      final name = full.substring(0, math.min(full.length, 64));
      if (tools.containsKey(name)) {
        throw StateError('MCP tools of ${session.name} clash as $name');
      }
      tools[name] = Tool<Object?>(
        name: name,
        description: _describe(session.name, raw, maxDescriptionChars),
        input: switch (raw['inputSchema']) {
          final Map<String, Object?> json => toolInputFromJson(json),
          _ => const ObjectSchema(properties: {}, additionalProperties: true),
        },
        decode: (json) => json,
        run: (input) async => mcpOutput(
          session.name,
          await session.callTool(remote, input! as Map<String, Object?>),
          maxOutputChars,
        ),
        timeout: timeout,
        requiresApproval: requireApproval,
      );
    }
  }
  return tools.values.toList();
}

String _describe(String server, Map<String, Object?> raw, int limit) {
  final text = raw['description'] is String
      ? raw['description']! as String
      : '';
  final kept = text.length > limit ? text.substring(0, limit) : text;
  return '$kept (tool from MCP server $server)'.trim();
}
