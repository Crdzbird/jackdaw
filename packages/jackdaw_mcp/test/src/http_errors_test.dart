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
  test('HTTP errors, empty streams and bad bodies fail clearly', () async {
    Future<Object?> send(http.StreamedResponse response) => HttpMcpTransport(
      Uri.parse('https://mcp.example/mcp'),
      client: MockClient.streaming((_, _) async => response),
    ).request({'id': 1, 'method': 'tools/list'});
    await expectLater(
      send(http.StreamedResponse(Stream.value(utf8.encode('x' * 300)), 401)),
      throwsA(isA<McpException>().having((e) => e.code, 'code', 401)),
    );
    await expectLater(
      send(
        http.StreamedResponse(
          const Stream.empty(),
          200,
          headers: {'content-type': 'text/event-stream'},
        ),
      ),
      throwsA(isA<McpException>()),
    );
    await expectLater(send(_json([1])), throwsA(isA<McpException>()));
    final owned = HttpMcpTransport(Uri.parse('https://mcp.example/mcp'));
    await owned.close();
  });
}
