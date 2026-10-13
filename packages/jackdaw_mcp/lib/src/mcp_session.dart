/// A connection to one MCP server, reduced to what an agent needs: listing
/// tools and calling them. Values are the raw JSON objects of the protocol.
///
/// `McpClient` implements it without extra dependencies; `DartMcpSession`
/// in `package:jackdaw_mcp/dart_mcp.dart` implements it with dart_mcp.
abstract interface class McpSession {
  /// Short name of the server, used to prefix its tool names.
  String get name;

  /// Every tool the server offers, as MCP `Tool` objects.
  Future<List<Map<String, Object?>>> listTools();

  /// Calls [tool] with [arguments] and returns the MCP `CallToolResult`.
  Future<Map<String, Object?>> callTool(
    String tool,
    Map<String, Object?> arguments,
  );

  /// Ends the session and frees its connection.
  Future<void> close();
}
