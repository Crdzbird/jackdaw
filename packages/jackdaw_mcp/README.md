# jackdaw_mcp

MCP client for `jackdaw`. Pre-release.

Turns the tools of a Model Context Protocol server into jackdaw tools. Two
backends implement the same `McpSession`, so the tools behave the same
whichever you pick:

- `McpClient`, a small client with no dependency beyond jackdaw, over
  `HttpMcpTransport` (Streamable HTTP, every platform including the web) or
  `startStdioServer` from `package:jackdaw_mcp/io.dart` (desktop).
- `DartMcpSession` from `package:jackdaw_mcp/dart_mcp.dart`, backed by the
  dart_mcp package, for apps that already use it or need its client
  features.

```dart
final session = await McpClient.connect(
  HttpMcpTransport(Uri.parse('https://example.com/mcp')),
  name: 'search',
);
final agent = Agent(
  model: model,
  tools: await mcpTools(session),
  store: InMemorySessionStore(),
);
```

Servers are treated as untrusted:

- Tool names get the server's prefix (`search_fetch`), so a server cannot
  shadow another server's tools or the app's own.
- Every call waits for approval unless `requireApproval: false` is passed.
- Descriptions and results are cut to a size limit, binary content is
  described rather than copied, and results tell the model that they are
  data, not instructions.
- Calls are never retried after an interruption.
- Servers started with `startStdioServer` do not inherit the app's
  environment, so API keys in it stay out of the server's reach.
- The client offers no capabilities, so servers cannot ask it for
  sampling, roots or elicitation.

Supported protocol versions: 2025-11-25, 2025-06-18 and 2025-03-26.
