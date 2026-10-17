# jackdaw_ollama

Native Ollama provider for `jackdaw`.

Talks to Ollama's own `/api/chat` endpoint rather than the OpenAI-compatible
one, so it can set the context size, `top_k` and how long the model stays
loaded.

```dart
final model = OllamaModel(
  model: 'qwen2.5:3b-instruct',
  numCtx: 8192,
  keepAlive: '10m',
);
```

- Streams text, tool calls (keeping server-side call ids) and thinking.
- A request's response schema is sent as Ollama's `format`, which
  constrains the output to that JSON Schema.
- Contract tests replay responses recorded from Ollama 0.33.3; set
  `JACKDAW_OLLAMA_MODEL` to also run an agent against a live server.
