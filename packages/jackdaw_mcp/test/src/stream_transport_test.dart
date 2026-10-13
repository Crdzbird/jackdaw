import 'dart:async';
import 'dart:convert';

import 'package:jackdaw_mcp/jackdaw_mcp.dart';
import 'package:test/test.dart';

void main() {
  test('answers server requests and ignores noise', () async {
    final incoming = StreamController<String>();
    final sent = <Map<String, Object?>>[];
    final transport = StreamMcpTransport(
      incoming.stream,
      (m) => sent.add(jsonDecode(m) as Map<String, Object?>),
    );
    final reply = transport.request({'jsonrpc': '2.0', 'id': 1, 'method': 'x'});
    incoming
      ..add('not json')
      ..add('[1]')
      ..add('{"jsonrpc":"2.0","id":"p","method":"ping"}')
      ..add('{"jsonrpc":"2.0","id":"s","method":"sampling/createMessage"}')
      ..add('{"jsonrpc":"2.0","method":"notifications/message"}')
      ..add('{"jsonrpc":"2.0","id":1,"result":{"ok":true}}');
    expect(await reply, containsPair('result', {'ok': true}));
    expect(sent[1], {
      'jsonrpc': '2.0',
      'id': 'p',
      'result': <String, Object?>{},
    });
    expect((sent[2]['error']! as Map)['code'], -32601);
    await transport.notify({'jsonrpc': '2.0', 'method': 'n'});
    expect(sent.last['method'], 'n');
    final pending = transport.request({'id': 2});
    await incoming.close();
    await expectLater(pending, throwsA(isA<McpException>()));
    await transport.close();
  });

  test('a failing stream fails pending requests', () async {
    final incoming = StreamController<String>();
    final transport = StreamMcpTransport(incoming.stream, (_) {});
    final pending = transport.request({'id': 1});
    incoming.addError(StateError('pipe broke'));
    await expectLater(pending, throwsA(isA<McpException>()));
    await incoming.close();
  });

  test('the client rejects unknown versions and maps errors', () async {
    Future<McpClient> connect(
      Map<String, Object?> Function(Map<Object?, Object?>) answer,
    ) {
      final incoming = StreamController<String>();
      late final StreamMcpTransport transport;
      transport = StreamMcpTransport(incoming.stream, (m) {
        final message = jsonDecode(m) as Map;
        if (message.containsKey('id')) {
          incoming.add(jsonEncode(answer(message)));
        }
      }, onClose: incoming.close);
      return McpClient.connect(transport, name: 's');
    }

    await expectLater(
      connect(
        (m) => {
          'id': m['id'],
          'result': {'protocolVersion': '1999-01-01'},
        },
      ),
      throwsA(isA<McpException>()),
    );
    await expectLater(
      connect(
        (m) => {
          'id': m['id'],
          'error': {'code': -32600, 'message': 'no'},
        },
      ),
      throwsA(
        isA<McpException>().having(
          (e) => '$e',
          'text',
          'McpException(-32600): no',
        ),
      ),
    );
    await expectLater(
      connect((m) => {'id': m['id']}),
      throwsA(isA<McpException>()),
    );
  });
}
