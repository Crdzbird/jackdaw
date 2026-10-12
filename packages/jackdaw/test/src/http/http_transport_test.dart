import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

HttpTransport transport(MockClient client) =>
    HttpTransport(provider: 'p', client: client);

MockClient replying(String body, int status, {Map<String, String>? headers}) =>
    MockClient.streaming(
      (request, _) async => http.StreamedResponse(
        Stream.value(utf8.encode(body)),
        status,
        headers: headers ?? const {},
      ),
    );

Future<ProviderException> failure(MockClient client) async {
  try {
    await transport(client)
        .postJson(Uri.parse('http://x/'), headers: const {}, body: null)
        .drain<void>();
  } on ProviderException catch (error) {
    return error;
  }
  throw StateError('expected a failure');
}

void main() {
  test('posts JSON with the given headers and streams the body', () async {
    late http.Request sent;
    final client = MockClient.streaming((request, _) async {
      sent = request as http.Request;
      return http.StreamedResponse(Stream.value(utf8.encode('ok')), 200);
    });
    final bytes = await transport(client)
        .postJson(
          Uri.parse('http://x/y'),
          headers: const {'x-key': 'k'},
          body: {'a': 1},
        )
        .expand((chunk) => chunk)
        .toList();
    expect(utf8.decode(bytes), 'ok');
    expect(sent.headers['x-key'], 'k');
    expect(sent.headers['content-type'], startsWith('application/json'));
    expect(jsonDecode(sent.body), {'a': 1});
  });

  test('maps error bodies in both common shapes', () async {
    final nested = await failure(
      replying(
        '{"type":"error","error":{"type":"rate_limit_error","message":"slow"}}',
        429,
        headers: const {'retry-after': '4'},
      ),
    );
    expect(nested.message, 'slow');
    expect(nested.retryAfter, const Duration(seconds: 4));
    expect(nested.provider, 'p');
    final flat = await failure(replying('{"error":"model not found"}', 404));
    expect(flat.message, 'model not found');
    expect((await failure(replying('<html>', 502))).message, 'HTTP 502');
  });

  test('cancelling aborts the request', () async {
    final trigger = Completer<Future<void>>();
    final body = StreamController<List<int>>();
    final client = MockClient.streaming((request, _) async {
      trigger.complete((request as http.Abortable).abortTrigger);
      return http.StreamedResponse(body.stream, 200);
    });
    body.add([1]);
    await transport(client)
        .postJson(Uri.parse('http://x/'), headers: const {}, body: null)
        .first;
    await (await trigger.future).timeout(const Duration(seconds: 1));
    await body.close();
  });
}
