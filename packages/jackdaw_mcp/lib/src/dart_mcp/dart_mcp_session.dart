import 'package:dart_mcp/client.dart' as mcp;
import 'package:jackdaw_mcp/src/mcp_exception.dart';
import 'package:jackdaw_mcp/src/mcp_session.dart';
import 'package:stream_channel/stream_channel.dart';

/// An [McpSession] backed by the dart_mcp package.
///
/// Use it to share a dart_mcp connection with other code, or to reach
/// dart_mcp features such as roots or sampling by passing your own
/// `MCPClient` subclass.
final class DartMcpSession implements McpSession {
  new _(this.name, this.connection);

  /// Initializes a session with the server called [name] over [channel],
  /// whose elements are single JSON messages, such as
  /// `stdioChannel(input: process.stdout, output: process.stdin)`.
  static Future<DartMcpSession> connect(
    StreamChannel<String> channel, {
    required String name,
    mcp.MCPClient? client,
  }) async {
    final owner =
        client ??
        mcp.MCPClient(mcp.Implementation(name: 'jackdaw', version: '0.1.0'));
    final connection = owner.connectServer(channel);
    final result = await connection.initialize(
      mcp.InitializeRequest(
        protocolVersion: mcp.ProtocolVersion.latestSupported,
        capabilities: owner.capabilities,
        clientInfo: owner.implementation,
      ),
    );
    if (result.protocolVersion?.isSupported != true) {
      await connection.shutdown();
      throw const McpException(-32602, 'unsupported protocol version');
    }
    connection.notifyInitialized();
    return DartMcpSession._(name, connection);
  }

  @override
  final String name;

  /// The underlying dart_mcp connection.
  final mcp.ServerConnection connection;

  @override
  Future<List<Map<String, Object?>>> listTools() async {
    final tools = <Map<String, Object?>>[];
    mcp.Cursor? cursor;
    for (var page = 0; page < 100; page++) {
      final result = await connection.listTools(
        mcp.ListToolsRequest(cursor: cursor),
      );
      tools.addAll([
        for (final tool in result.tools) tool as Map<String, Object?>,
      ]);
      cursor = result.nextCursor;
      if (cursor == null) return tools;
    }
    return tools;
  }

  @override
  Future<Map<String, Object?>> callTool(
    String tool,
    Map<String, Object?> arguments,
  ) async => await connection.callTool(
    mcp.CallToolRequest(name: tool, arguments: arguments),
  ) as Map<String, Object?>;

  @override
  Future<void> close() => connection.shutdown();
}
