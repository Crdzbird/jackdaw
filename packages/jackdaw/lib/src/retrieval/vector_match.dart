/// One search hit: a stored id and its cosine similarity to the query.
final class VectorMatch {
  /// Creates a hit for [id] with [score].
  const factory(String id, double score) = VectorMatch._;

  const new _(this.id, this.score);

  /// Id the vector was stored under.
  final String id;

  /// Cosine similarity, from -1 to 1; higher is closer.
  final double score;

  @override
  String toString() => 'VectorMatch($id, $score)';
}
