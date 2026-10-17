## 1.0.0

First stable release.

- Streaming chat completions with tool calls and token usage, for
  OpenAI and any OpenAI-compatible server through `baseUrl`.
- Cancelling the stream aborts the HTTP request; errors surface as
  `ProviderException` with the status code and `Retry-After`.
- The API key is held in a `Secret`, which never prints its value.
