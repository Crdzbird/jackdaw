import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jackdaw_mcp/jackdaw_mcp.dart';
import 'package:test/test.dart';

http.StreamedResponse _json(
  Object body, {
  Map<String, String> headers = const {},
}) => http.StreamedResponse(
  Stream.value(utf8.encode(jsonEncode(body))),
  200,
  headers: {'content-type': 'application/json', ...headers},
);

void main() {
  test('runs a session over JSON and event-stream answers', () async {
    final seen = <http.BaseRequest>[];
    final client = MockClient.streaming((request, body) async {
      seen.add(request);
      if (request.method == 'DELETE') {
        return http.StreamedResponse(const Stream.empty(), 200);
      }
      final message = jsonDecode(await body.bytesToString()) as Map;
      return switch (message['method']) {
        'initialize' => _json(
          {
            'jsonrpc': '2.0',
            'id': message['id'],
            'result': {'protocolVersion': '2025-06-18'},
          },
          headers: {'mcp-session-id': 'sess-1'},
        ),
        'notifications/initialized' => http.StreamedResponse(
          const Stream.empty(),
          202,
        ),
        _ => http.StreamedResponse(
          Stream.value(
            utf8.encode(
              'data: not json\n\n'
              'data: {"jsonrpc":"2.0","method":"notifications/progress"}\n\n'
              'data: {"jsonrpc":"2.0","id":99,"result":{}}\n\n'
              'data: ${jsonEncode({
                'jsonrpc': '2.0',
                'id': message['id'],
                'result': {
                  'tools': [
                    {'name': 'echo'},
                  ],
                },
              })}\n\n',
            ),
          ),
          200,
          headers: {'content-type': 'text/event-stream'},
        ),
      };
    });
    final transport = HttpMcpTransport(
      Uri.parse('https://mcp.example/mcp'),
      client: client,
      headers: const {'authorization': 'Bearer t'},
    );
    final session = await McpClient.connect(transport, name: 'remote');
    expect(session.protocolVersion, '2025-06-18');
    expect((await session.listTools()).single['name'], 'echo');
    await session.close();
    expect(seen.first.headers['accept'], 'application/json, text/event-stream');
    expect(seen.first.headers.containsKey('mcp-session-id'), isFalse);
    expect(seen[1].headers['mcp-session-id'], 'sess-1');
    expect(seen[2].headers['mcp-protocol-version'], '2025-06-18');
    expect(seen.last.method, 'DELETE');
    expect(seen.every((r) => r.headers['authorization'] == 'Bearer t'), isTrue);
  });
}
