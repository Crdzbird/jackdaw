# jackdaw_gemini

Gemini provider for `jackdaw`.

Streams the Gemini API's `generateContent` with function calls, JSON schema
output (`responseJsonSchema`) and token usage including thinking tokens.

```dart
final model = GeminiModel(
  model: 'gemini-3.8-flash',
  apiKey: Secret(apiKey),
);
```

- Thinking parts and the `thoughtSignature` on function calls are kept in
  the transcript and sent back unchanged, which Gemini requires for
  function calling with thinking models.
- Tool results are returned as `functionResponse` parts matched by call id.
- Cancelling the stream aborts the HTTP request.

Do not ship API keys inside client apps; use them on a server, or for local
development only.
