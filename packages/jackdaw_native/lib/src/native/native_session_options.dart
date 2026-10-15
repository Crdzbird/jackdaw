/// Settings for a native inference session.
final class NativeSessionOptions {
  /// Creates options; zero picks the native default.
  const factory({
    int contextTokens,
    int threads,
    int batchTokens,
    int generateThreads,
  }) = NativeSessionOptions._;

  const new _({
    this.contextTokens = 4096,
    this.threads = 0,
    this.batchTokens = 0,
    this.generateThreads = 0,
  });

  /// Context window in tokens.
  final int contextTokens;

  /// Worker threads; 0 lets the core choose.
  final int threads;

  /// Prompt batch size; 0 lets the core choose.
  final int batchTokens;

  /// Threads that generate tokens, at most [threads]; 0 uses [threads].
  /// Generation is bound by memory on most phones, so two threads often
  /// generate as fast as four while leaving cores to the app. Needs native
  /// 0.1.0-dev.6 or later.
  final int generateThreads;
}
