# jackdaw_anthropic

Anthropic provider for `jackdaw`.

Streams Claude messages through the Messages API with tool calls,
structured output (`output_config.format`) and token usage including cached
input tokens.

```dart
final model = AnthropicModel(
  model: 'claude-opus-5-5',
  apiKey: Secret(apiKey),
);
```

- Thinking blocks are recorded as `ReasoningPart`s and sent back unchanged
  on later turns, which Claude requires during tool use.
- Sampling settings such as `temperature` are sent only when you set them,
  because newer Claude models reject them.
- Cancelling the stream aborts the HTTP request; errors surface as
  `ProviderException`, including errors sent inside the stream.

Do not ship API keys inside client apps; use them on a server, or for local
development only.
