import 'dart:io' as io;

import 'package:dart_mcp/server.dart';

/// An MCP server built with dart_mcp, used to test both clients.
final class BirdServer extends MCPServer with ToolsSupport {
  new(super.channel)
    : super.fromStreamChannel(
        implementation: Implementation(name: 'birds', version: '1.0.0'),
      ) {
    registerTool(
      Tool(
        name: 'echo',
        description: 'Repeats text',
        inputSchema: Schema.object(
          properties: {'text': Schema.string()},
          required: ['text'],
        ),
      ),
      (request) => CallToolResult(
        content: [TextContent(text: request.arguments!['text']! as String)],
      ),
    );
    registerTool(
      Tool(
        name: 'env',
        description: 'Reads an environment variable of the server',
        inputSchema: Schema.object(properties: {'name': Schema.string()}),
      ),
      (request) => CallToolResult(
        content: [
          TextContent(
            text:
                io.Platform.environment[request.arguments!['name']!
                    as String] ??
                '(unset)',
          ),
        ],
      ),
    );
    registerTool(
      Tool(name: 'fail', inputSchema: Schema.object()),
      (request) => CallToolResult(
        content: [TextContent(text: 'the bird flew away')],
        isError: true,
      ),
    );
    registerTool(
      Tool(name: 'picture', inputSchema: Schema.object()),
      (request) => CallToolResult(
        content: [ImageContent(data: 'AAAA', mimeType: 'image/png')],
        structuredContent: {'species': 'jackdaw'},
      ),
    );
  }
}
