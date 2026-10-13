/// What a text is embedded for. Many embedding models encode queries and
/// documents differently, so retrieval asks for the right kind.
enum EmbeddingKind {
  /// Text stored in an index.
  document,

  /// A search query compared against stored documents.
  query,
}
