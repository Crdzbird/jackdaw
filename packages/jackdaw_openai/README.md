# jackdaw_openai

OpenAI provider for `jackdaw`. Pre-release.

Streams chat completions with tool calls and token usage. Works with any
OpenAI-compatible server by setting `baseUrl`, for example Ollama
(`http://localhost:11434/v1`), LM Studio or vLLM.

```dart
final model = OpenAiModel(
  model: 'gpt-4o-mini',
  apiKey: Secret(apiKey),
);
```

- Cancelling the stream aborts the HTTP request.
- Errors surface as `ProviderException` with status code and `Retry-After`.
- Pass your own `http.Client` for proxies, connection reuse or recording.
- The API key is held in a `Secret`, which never prints its value.

Do not ship provider API keys inside client apps; keys in a browser or a
mobile binary can be extracted. Use them on a server, or for local
development only.

Run the example against OpenAI or a local server:

```bash
OPENAI_BASE_URL=http://localhost:11434/v1 OPENAI_MODEL=qwen2.5:3b-instruct dart run example/main.dart
```
