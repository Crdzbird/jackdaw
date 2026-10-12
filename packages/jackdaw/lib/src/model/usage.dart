/// Token usage reported for one or more model calls.
///
/// A count is `null` when the provider did not report it, so an unknown
/// count is never confused with zero.
final class Usage {
  /// Creates a usage record.
  const factory({int? inputTokens, int? outputTokens}) = Usage._;

  const new _({this.inputTokens, this.outputTokens});

  /// Tokens sent to the model, when known.
  final int? inputTokens;

  /// Tokens produced by the model, when known.
  final int? outputTokens;

  /// Adds two records; a count stays `null` only if both sides lack it.
  Usage operator +(Usage other) => Usage(
    inputTokens: _sum(inputTokens, other.inputTokens),
    outputTokens: _sum(outputTokens, other.outputTokens),
  );

  static int? _sum(int? a, int? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a + b;
  }
}
