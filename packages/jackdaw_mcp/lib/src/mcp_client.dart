import 'package:jackdaw_mcp/src/mcp_exception.dart';
import 'package:jackdaw_mcp/src/mcp_session.dart';
import 'package:jackdaw_mcp/src/mcp_transport.dart';

/// Protocol versions this client speaks, newest first.
const List<String> mcpProtocolVersions = [
  '2025-11-25',
  '2025-06-18',
  '2025-03-26',
];

/// A small MCP client over any [McpTransport], with no dependency beyond
/// jackdaw. It asks for no client capabilities, so servers cannot request
/// sampling, roots or elicitation from it.
final class McpClient implements McpSession {
  new _(this.name, this._transport, this.protocolVersion);

  /// Initializes a session over [transport] with the server called [name].
  ///
  /// Fails with [McpException] when the server speaks none of
  /// [mcpProtocolVersions].
  static Future<McpClient> connect(
    McpTransport transport, {
    required String name,
    String clientName = 'jackdaw',
    String clientVersion = '0.1.0',
  }) async {
    final client = McpClient._(name, transport, mcpProtocolVersions.first);
    final result = await client._call('initialize', {
      'protocolVersion': mcpProtocolVersions.first,
      'capabilities': <String, Object?>{},
      'clientInfo': {'name': clientName, 'version': clientVersion},
    });
    final version = result['protocolVersion'];
    if (version is! String || !mcpProtocolVersions.contains(version)) {
      await transport.close();
      throw McpException(-32602, 'unsupported protocol version $version');
    }
    client.protocolVersion = version;
    await transport.notify({
      'jsonrpc': '2.0',
      'method': 'notifications/initialized',
    });
    return client;
  }

  @override
  final String name;

  /// The version agreed with the server.
  String protocolVersion;

  final McpTransport _transport;
  int _id = 0;

  @override
  Future<List<Map<String, Object?>>> listTools() async {
    final tools = <Map<String, Object?>>[];
    String? cursor;
    for (var page = 0; page < 100; page++) {
      final result = await _call('tools/list', {'cursor': ?cursor});
      tools.addAll([
        for (final tool in result['tools'] as List? ?? const [])
          if (tool is Map<String, Object?>) tool,
      ]);
      cursor = result['nextCursor'] as String?;
      if (cursor == null) return tools;
    }
    return tools;
  }

  @override
  Future<Map<String, Object?>> callTool(
    String tool,
    Map<String, Object?> arguments,
  ) => _call('tools/call', {'name': tool, 'arguments': arguments});

  @override
  Future<void> close() => _transport.close();

  Future<Map<String, Object?>> _call(
    String method,
    Map<String, Object?> params,
  ) async {
    final response = await _transport.request({
      'jsonrpc': '2.0',
      'id': ++_id,
      'method': method,
      'params': params,
    });
    return switch (response) {
      {'result': final Map<String, Object?> result} => result,
      {'error': {'code': final int code, 'message': final String message}} =>
        throw McpException(code, message),
      _ => throw const McpException(-32603, 'malformed response'),
    };
  }
}
