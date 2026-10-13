import 'package:jackdaw/src/retrieval/vector_match.dart';

/// Keeps the [k] best matches seen so far, best first.
final class TopK {
  /// Creates an empty selection of size [k].
  factory(int k) = TopK._;

  new _(this.k);

  /// How many matches are kept.
  final int k;

  final List<VectorMatch> _best = [];

  /// The lowest score that would still be kept.
  double get floor =>
      _best.length < k ? double.negativeInfinity : _best.last.score;

  /// Offers a match; it is kept when it beats [floor].
  void offer(String id, double score) {
    if (k <= 0 || score <= floor) return;
    var at = _best.length;
    while (at > 0 && _best[at - 1].score < score) {
      at--;
    }
    _best.insert(at, VectorMatch(id, score));
    if (_best.length > k) _best.removeLast();
  }

  /// The kept matches, best first.
  List<VectorMatch> get matches => List.unmodifiable(_best);
}
