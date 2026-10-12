/// A failure reported by the native core.
final class NativeException implements Exception {
  /// Creates an exception for a `jackdaw_status` [status].
  const factory(int status, String message) = NativeException._;

  const new _(this.status, this.message);

  /// The `jackdaw_status` code.
  final int status;

  /// Explanation from the native core.
  final String message;

  @override
  String toString() => 'NativeException($status): $message';
}
