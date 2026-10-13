@TestOn('vm')
library;

import 'dart:io';

import 'package:jackdaw_mcp/io.dart';
import 'package:jackdaw_mcp/jackdaw_mcp.dart';
import 'package:test/test.dart';

void main() {
  test('a stdio server gets no inherited secrets', () async {
    final leaked = Platform.environment.keys.firstWhere(
      (k) =>
          !const {'PATH', 'HOME', 'SystemRoot', 'TEMP', 'TMPDIR'}.contains(k),
    );
    final stderr = <String>[];
    final transport = await startStdioServer(
      Platform.resolvedExecutable,
      ['run', 'test/fixtures/stdio_server.dart'],
      environment: const {'BIRD': 'jackdaw'},
      onStderr: stderr.add,
    );
    final client = await McpClient.connect(transport, name: 'local');
    Future<String> env(String name) async {
      final result = await client.callTool('env', {'name': name});
      return (mcpOutput('local', result, 100000)['content']! as List)
              .cast<Map<String, Object?>>()
              .single['text']!
          as String;
    }

    expect(await env('BIRD'), 'jackdaw');
    expect(await env(leaked), '(unset)');
    expect(await env('PATH'), Platform.environment['PATH']);
    await client.close();
  }, timeout: const Timeout(Duration(minutes: 2)));
}
