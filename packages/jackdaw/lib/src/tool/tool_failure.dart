/// Thrown by a tool's handler to fail with [output] the model can act on,
/// such as a list of problems to correct, instead of an error message.
///
/// The result is marked as an error, so it does not count towards the
/// tool's calls per turn.
final class ToolFailure implements Exception {
  /// Creates a failure that returns [output] to the model.
  const factory(Object? output) = ToolFailure._;

  const new _(this.output);

  /// The JSON-encodable output the model receives.
  final Object? output;

  @override
  String toString() => 'ToolFailure: $output';
}
