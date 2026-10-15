/// A value or function call that could not be evaluated.
///
/// The [code] is the A2UI error code: `EXPRESSION_ERROR` for a call that
/// is not allowed where it appears, `EXECUTION_ERROR` for one that failed.
final class UiEvalException implements Exception {
  /// Creates the failure [code] described by [message].
  const factory(String code, String message) = UiEvalException._;

  const new _(this.code, this.message);

  /// The A2UI error code.
  final String code;

  /// What went wrong.
  final String message;

  @override
  String toString() => '$code: $message';
}
