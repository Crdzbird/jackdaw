import 'dart:js_interop';

/// A `Wllama` instance from the wllama 3.8 ES module.
extension type Wllama._(JSObject _) implements JSObject {
  /// Downloads (or reads from cache) and loads a GGUF model.
  external JSPromise<JSAny?> loadModelFromUrl(JSString url, JSObject params);

  /// Runs an OpenAI-compatible chat completion.
  ///
  /// With `stream: true` and an `onData` callback the promise completes
  /// after the last chunk has been delivered.
  external JSPromise<JSAny?> createChatCompletion(JSObject options);

  /// Embeds `input`, a string or list of strings, OpenAI style. Needs a
  /// model loaded with `embeddings: true`.
  external JSPromise<JSAny?> createEmbedding(JSObject options);

  /// Unloads the model and frees its memory.
  external JSPromise<JSAny?> exit();
}
