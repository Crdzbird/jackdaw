import 'dart:async';
import 'dart:convert';

import 'package:jackdaw_mcp/src/mcp_exception.dart';
import 'package:jackdaw_mcp/src/mcp_transport.dart';

/// An [McpTransport] over a stream of JSON messages, one per element, such
/// as the lines of a server's stdout.
///
/// Requests from the server are answered too: `ping` succeeds and every
/// other method is refused, because the client offers no capabilities.
final class StreamMcpTransport implements McpTransport {
  /// Reads [messages] and writes with [send]; [onClose] frees the channel.
  factory(
    Stream<String> messages,
    void Function(String message) send, {
    Future<void> Function()? onClose,
  }) {
    final transport = StreamMcpTransport._(send, onClose);
    transport._subscription = messages.listen(
      transport._receive,
      onDone: transport._failPending,
      onError: (Object _) => transport._failPending(),
    );
    return transport;
  }

  new _(this._send, this._onClose);

  final void Function(String message) _send;
  final Future<void> Function()? _onClose;
  final Map<Object?, Completer<Map<String, Object?>>> _pending = {};
  StreamSubscription<String>? _subscription;

  @override
  Future<Map<String, Object?>> request(Map<String, Object?> message) {
    final reply = Completer<Map<String, Object?>>();
    _pending[message['id']] = reply;
    _send(jsonEncode(message));
    return reply.future;
  }

  @override
  Future<void> notify(Map<String, Object?> message) async =>
      _send(jsonEncode(message));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _failPending();
    await _onClose?.call();
  }

  void _receive(String line) {
    final Object? message;
    try {
      message = jsonDecode(line);
    } on FormatException {
      return;
    }
    if (message is! Map<String, Object?>) return;
    final id = message['id'];
    if (message['method'] case final String method when id != null) {
      _send(jsonEncode(_answer(id, method)));
      return;
    }
    _pending.remove(id)?.complete(message);
  }

  Map<String, Object?> _answer(Object id, String method) => {
    'jsonrpc': '2.0',
    'id': id,
    if (method == 'ping') 'result': <String, Object?>{},
    if (method != 'ping')
      'error': {'code': -32601, 'message': 'method not supported: $method'},
  };

  void _failPending() {
    for (final reply in _pending.values) {
      reply.completeError(const McpException(-32000, 'connection closed'));
    }
    _pending.clear();
  }
}
