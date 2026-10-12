# jackdaw_web

In-browser inference for `jackdaw`. Pre-release. Web only.

`WebLocalModel` runs a GGUF model with [wllama](https://github.com/ngxson/wllama)
3.8, llama.cpp compiled to WebAssembly, behind the same `LanguageModel`
interface as every other jackdaw model.

```dart
final model = await WebLocalModel.open(
  modelUrl: '/models/qwen2.5-1.5b-instruct-q4_k_m.gguf',
  moduleUrl: '/wllama/esm/index.js',
  wasmUrl: '/wllama/esm/wasm/wllama.wasm',
);
final answer = await generateJson(model, [Message.user('Is it day?')], schema);
```

- Structured output uses the same GBNF grammar compiler as `jackdaw_native`.
- Tool calls, token usage and finish reasons arrive in the OpenAI format
  wllama emits, decoded by `jackdaw_openai`'s wire helpers.
- Cancelling the stream aborts generation through an `AbortSignal`.

The wllama JavaScript module and wasm binary are not bundled and are never
fetched implicitly: host them with your app, or pass URLs of a pinned CDN
copy such as `https://cdn.jsdelivr.net/npm/@wllama/wllama@3.8.1/esm/index.js`.
Multi-threading needs the page served with `Cross-Origin-Opener-Policy:
same-origin` and `Cross-Origin-Embedder-Policy: require-corp`; without them
wllama runs single-threaded. Model files above 2 GB must be split.
