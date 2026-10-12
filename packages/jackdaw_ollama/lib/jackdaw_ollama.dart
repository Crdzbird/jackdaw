/// Native Ollama provider for jackdaw.
///
/// `OllamaModel` streams `/api/chat` with tool calls, JSON schema output and
/// Ollama options such as `num_ctx`.
library;

export 'src/ollama_model.dart';
