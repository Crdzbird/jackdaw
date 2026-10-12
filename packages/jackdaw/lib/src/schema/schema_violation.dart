/// A single reason why a value does not match a schema.
final class SchemaViolation {
  /// Creates a violation found at [path] described by [message].
  const factory(String path, String message) = SchemaViolation._;

  const new _(this.path, this.message);

  /// Location of the offending value, written as `$.field[0].child`.
  final String path;

  /// Human and model readable explanation.
  final String message;

  @override
  String toString() => '$path $message';
}
