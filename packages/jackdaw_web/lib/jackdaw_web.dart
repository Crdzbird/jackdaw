/// In-browser inference for jackdaw.
///
/// `WebLocalModel` runs GGUF models with wllama, llama.cpp compiled to
/// WebAssembly, behind the same `LanguageModel` interface as every other
/// model. `WebEmbedder` embeds text in the browser for retrieval with the
/// pure Dart `FlatVectorIndex`. Web only.
library;

export 'src/web_embedder.dart';
export 'src/web_local_model.dart';
