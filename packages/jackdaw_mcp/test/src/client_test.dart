@TestOn('vm')
library;

import 'package:jackdaw_mcp/jackdaw_mcp.dart';
import 'package:test/test.dart';

import 'support/linked.dart';

void main() {
  test('lists and calls tools of a dart_mcp server', () async {
    final client = await McpClient.connect(linkedBirdServer(), name: 'birds');
    expect(mcpProtocolVersions, contains(client.protocolVersion));
    final tools = await client.listTools();
    expect(tools.map((t) => t['name']), containsAll(['echo', 'fail']));
    final echo = await client.callTool('echo', {'text': 'caw'});
    expect(mcpOutput('birds', echo, 100)['content'], [
      {'type': 'text', 'text': 'caw'},
    ]);
    final missing = await client.callTool('nope', {});
    expect(missing['isError'], isTrue);
    await client.close();
  });
}
