@TestOn('vm')
library;

import 'dart:convert';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_mcp/dart_mcp.dart';
import 'package:jackdaw_mcp/jackdaw_mcp.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import 'support/linked.dart';

void main() {
  test('dart_mcp sessions feed the same tool conversion', () async {
    final session = await DartMcpSession.connect(birdChannel(), name: 'birds');
    final tools = await mcpTools(session, requireApproval: false);
    final echo = tools.firstWhere((t) => t.name == 'birds_echo');
    expect(echo.input.required, ['text']);
    final result = await echo.invoke(
      const ToolCallPart(
        id: 'c',
        name: 'birds_echo',
        arguments: {'text': 'hi'},
      ),
    );
    expect((result.output! as Map)['content'], [
      {'type': 'text', 'text': 'hi'},
    ]);
    final picture = await tools
        .firstWhere((t) => t.name == 'birds_picture')
        .invoke(
          const ToolCallPart(id: 'p', name: 'birds_picture', arguments: {}),
        );
    final output = picture.output! as Map;
    expect(output['structured'], {'species': 'jackdaw'});
    expect((output['content'] as List).single, {
      'type': 'image',
      'mimeType': 'image/png',
      'omitted': 'binary data is not shown to the model',
    });
    final failed = await tools
        .firstWhere((t) => t.name == 'birds_fail')
        .invoke(const ToolCallPart(id: 'f', name: 'birds_fail', arguments: {}));
    expect(failed.isError, isTrue);
    expect('${failed.output}', contains('the bird flew away'));
    expect(session.connection.serverInfo?.name, 'birds');
    await session.close();
  });

  test('dart_mcp sessions refuse unsupported versions', () async {
    final link = StreamChannelController<String>();
    link.foreign.stream.listen((line) {
      final message = jsonDecode(line) as Map<String, Object?>;
      if (message['method'] != 'initialize') return;
      link.foreign.sink.add(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': message['id'],
          'result': {
            'protocolVersion': '1999-01-01',
            'capabilities': <String, Object?>{},
            'serverInfo': {'name': 'old', 'version': '0'},
          },
        }),
      );
    });
    await expectLater(
      DartMcpSession.connect(link.local, name: 'old'),
      throwsA(isA<McpException>()),
    );
  });
}
