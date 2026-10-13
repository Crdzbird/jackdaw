/// Gemini provider for jackdaw.
///
/// `GeminiModel` streams `generateContent` with function calls, JSON schema
/// output and thought signatures. `GeminiEmbedder` embeds documents and
/// queries for retrieval.
library;

export 'src/gemini_embedder.dart';
export 'src/gemini_model.dart';
