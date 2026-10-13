import 'package:jackdaw/src/retrieval/document.dart';

/// A document returned for a query, with its similarity to it.
final class RetrievedDocument {
  /// Pairs [document] with [score].
  const factory(Document document, double score) = RetrievedDocument._;

  const new _(this.document, this.score);

  /// The stored document.
  final Document document;

  /// Cosine similarity to the query; higher is closer.
  final double score;
}
