/// Counts and timings of the last finished native generation.
final class NativeStats {
  /// Creates a statistics record.
  const factory({
    required int promptTokens,
    required int reusedTokens,
    required int generatedTokens,
    required double promptMs,
    required double firstTokenMs,
    required double totalMs,
  }) = NativeStats._;

  const new _({
    required this.promptTokens,
    required this.reusedTokens,
    required this.generatedTokens,
    required this.promptMs,
    required this.firstTokenMs,
    required this.totalMs,
  });

  /// Tokens in the prompt.
  final int promptTokens;

  /// Prompt tokens served from the cache of the previous turn.
  final int reusedTokens;

  /// Tokens generated.
  final int generatedTokens;

  /// Milliseconds spent on the prompt.
  final double promptMs;

  /// Milliseconds until the first generated token.
  final double firstTokenMs;

  /// Milliseconds for the whole generation.
  final double totalMs;
}
