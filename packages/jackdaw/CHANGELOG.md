## 1.0.0

First stable release.

- Codegen-free schemas that serialize for providers and validate
  offline, and typed tools whose arguments are checked before they run.
- An agent loop with a step limit, concurrent tool calls, human
  approval, sub-agents, context budgets and summed usage.
- Durable sessions that survive a killed process, policies that treat
  tools from MCP servers and tool output as untrusted, and traces that
  redact secrets.
- Streaming everywhere; cancelling a stream cancels the underlying call.
- Retrieval: embeddings, chunking and an exact vector index.
- Generative UI on A2UI v1.0: catalogs, schemas, grammars for local
  models, and UiSurfaces, which checks every message against the
  catalog and the component tree before it applies; `trusted` skips the
  checks for messages from a source the app fully trusts.
- Runs on the Dart VM, Flutter and the web, compiled to JavaScript or
  WebAssembly.
