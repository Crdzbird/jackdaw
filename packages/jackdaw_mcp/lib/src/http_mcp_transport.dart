import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_mcp/src/mcp_exception.dart';
import 'package:jackdaw_mcp/src/mcp_transport.dart';

/// An [McpTransport] for the MCP Streamable HTTP transport. Works on every
/// platform, including the web.
///
/// Each message is a POST to [endpoint]. Answers arrive as JSON or as a
/// server-sent event stream; the session id the server assigns is sent
/// back on every later request and the session is ended on [close].
final class HttpMcpTransport implements McpTransport {
  /// Talks to [endpoint], adding [headers] such as an authorization header.
  factory(Uri endpoint, {http.Client? client, Map<String, String> headers}) =
      HttpMcpTransport._;

  new _(this.endpoint, {this._client, this.headers = const {}});

  /// URL of the server's MCP endpoint.
  final Uri endpoint;

  /// Extra headers sent with every request.
  final Map<String, String> headers;

  final http.Client? _client;
  late final http.Client _http = _client ?? http.Client();
  String? _session;
  String? _version;

  @override
  Future<Map<String, Object?>> request(Map<String, Object?> message) async {
    final response = await _post(message);
    final type = response.headers['content-type'] ?? '';
    final reply = type.contains('text/event-stream')
        ? await _fromEvents(response.stream, message['id'])
        : jsonDecode(await response.stream.bytesToString());
    if (reply is! Map<String, Object?>) {
      throw const McpException(-32603, 'malformed response');
    }
    if (reply case {'result': {'protocolVersion': final String version}}) {
      _version = version;
    }
    return reply;
  }

  @override
  Future<void> notify(Map<String, Object?> message) async {
    await (await _post(message)).stream.drain<void>();
  }

  @override
  Future<void> close() async {
    if (_session case final session?) {
      final request = http.Request('DELETE', endpoint)
        ..headers.addAll({...headers, 'mcp-session-id': session});
      await _http
          .send(request)
          .then((r) => r.stream.drain<void>(), onError: (Object _) {});
    }
    if (_client == null) _http.close();
  }

  Future<http.StreamedResponse> _post(Map<String, Object?> message) async {
    final request = http.Request('POST', endpoint)
      ..headers.addAll({
        ...headers,
        'content-type': 'application/json',
        'accept': 'application/json, text/event-stream',
        'mcp-session-id': ?_session,
        'mcp-protocol-version': ?_version,
      })
      ..body = jsonEncode(message);
    final response = await _http.send(request);
    _session = response.headers['mcp-session-id'] ?? _session;
    if (response.statusCode >= 400) {
      final body = await response.stream.bytesToString();
      final text = body.length > 200 ? body.substring(0, 200) : body;
      throw McpException(response.statusCode, 'HTTP error: $text');
    }
    return response;
  }

  Future<Object?> _fromEvents(Stream<List<int>> body, Object? id) async {
    await for (final event in body.transform(const SseDecoder())) {
      final Object? message;
      try {
        message = jsonDecode(event.data);
      } on FormatException {
        continue;
      }
      if (message case final Map<String, Object?> reply
          when reply['id'] == id && !reply.containsKey('method')) {
        return reply;
      }
    }
    throw const McpException(-32000, 'stream ended without a response');
  }
}
