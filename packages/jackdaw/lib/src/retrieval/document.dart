/// A piece of text that can be indexed and retrieved.
final class Document {
  /// Creates a document [id] holding [text].
  const factory({
    required String id,
    required String text,
    Map<String, Object?> metadata,
  }) = Document._;

  const new _({required this.id, required this.text, this.metadata = const {}});

  /// Reads a document written by [toJson].
  factory fromJson(Map<String, Object?> json) => Document(
    id: json['id']! as String,
    text: json['text']! as String,
    metadata: Map<String, Object?>.from(json['metadata']! as Map),
  );

  /// Unique id, also used in the vector index.
  final String id;

  /// The content.
  final String text;

  /// JSON-compatible extra data such as the source file or page.
  final Map<String, Object?> metadata;

  /// A JSON form of the document.
  Map<String, Object?> toJson() => {
    'id': id,
    'text': text,
    'metadata': metadata,
  };
}
