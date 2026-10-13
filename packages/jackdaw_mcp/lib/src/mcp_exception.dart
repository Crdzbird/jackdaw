/// An error reported by an MCP server or its transport.
final class McpException implements Exception {
  /// Creates an error with JSON-RPC [code] and [message].
  const factory(int code, String message) = McpException._;

  const new _(this.code, this.message);

  /// JSON-RPC error code, or an HTTP status for transport failures.
  final int code;

  /// What went wrong, as reported by the server.
  final String message;

  @override
  String toString() => 'McpException($code): $message';
}
