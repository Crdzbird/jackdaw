/// Sampling settings for one native generation.
final class NativeGenerateOptions {
  /// Creates options; the defaults decode greedily.
  const factory({
    double temperature,
    int topK,
    double topP,
    int seed,
    int maxTokens,
    String? grammar,
  }) = NativeGenerateOptions._;

  const new _({
    this.temperature = 0,
    this.topK = 0,
    this.topP = 1,
    this.seed = 0,
    this.maxTokens = 0,
    this.grammar,
  });

  /// Sampling temperature; 0 decodes greedily.
  final double temperature;

  /// Top-k cut-off; 0 disables it.
  final int topK;

  /// Nucleus cut-off; 1 disables it.
  final double topP;

  /// Sampling seed.
  final int seed;

  /// Token limit; 0 runs until the context is full.
  final int maxTokens;

  /// GBNF grammar with a `root` rule, or `null` for free text.
  final String? grammar;
}
