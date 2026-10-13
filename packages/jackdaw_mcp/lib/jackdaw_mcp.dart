/// MCP client for jackdaw.
///
/// `mcpTools` turns the tools of a Model Context Protocol server into
/// jackdaw tools, treating the server as untrusted. Connect with
/// `McpClient` over `HttpMcpTransport` on any platform, over
/// `startStdioServer` from `package:jackdaw_mcp/io.dart` on desktop, or
/// with dart_mcp through `package:jackdaw_mcp/dart_mcp.dart`.
library;

export 'src/http_mcp_transport.dart';
export 'src/mcp_client.dart';
export 'src/mcp_exception.dart';
export 'src/mcp_output.dart';
export 'src/mcp_session.dart';
export 'src/mcp_tools.dart';
export 'src/mcp_transport.dart';
export 'src/stream_mcp_transport.dart';
