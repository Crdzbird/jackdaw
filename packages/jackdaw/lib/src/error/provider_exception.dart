/// A failure reported by a model provider.
final class ProviderException implements Exception {
  /// Creates an exception for [provider] with [message].
  const factory({
    required String provider,
    required String message,
    int? statusCode,
    Duration? retryAfter,
  }) = ProviderException._;

  const new _({
    required this.provider,
    required this.message,
    this.statusCode,
    this.retryAfter,
  });

  /// Name of the provider, such as `openai`.
  final String provider;

  /// Explanation from the provider or the transport.
  final String message;

  /// HTTP status code, when the failure came from an HTTP response.
  final int? statusCode;

  /// How long the provider asked callers to wait before retrying.
  final Duration? retryAfter;

  /// Whether retrying the same request may succeed.
  bool get isRetryable => statusCode == 429 || (statusCode ?? 0) >= 500;

  @override
  String toString() => 'ProviderException($provider, $statusCode): $message';
}
