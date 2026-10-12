/// Settings for a native inference session.
final class NativeSessionOptions {
  /// Creates options; zero picks the native default.
  const factory({int contextTokens, int threads, int batchTokens}) =
      NativeSessionOptions._;

  const new _({
    this.contextTokens = 4096,
    this.threads = 0,
    this.batchTokens = 0,
  });

  /// Context window in tokens.
  final int contextTokens;

  /// Worker threads; 0 lets the core choose.
  final int threads;

  /// Prompt batch size; 0 lets the core choose.
  final int batchTokens;
}
