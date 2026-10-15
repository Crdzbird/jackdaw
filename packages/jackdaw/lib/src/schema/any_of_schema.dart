part of 'schema.dart';

/// Schema for a value that matches at least one of several [options], such
/// as a string or an object that binds to data.
///
/// An invalid value is explained by the option it comes closest to, one
/// whose type it has where there is such an option. Prefer [UnionSchema]
/// for objects that carry a tag. Constrained decoding emits a value of
/// exactly one option.
final class AnyOfSchema extends Schema {
  /// Creates a schema that accepts a value matching any of [options].
  const factory(List<Schema> options, {String? description}) = AnyOfSchema._;

  const new _(this.options, {super.description}) : super._();

  /// The schemas a value may match.
  final List<Schema> options;

  @override
  Map<String, Object?> toJsonWith(SchemaEncoder child) => {
    if (description != null) 'description': description,
    'anyOf': [for (final option in options) child(option)],
  };

  @override
  List<SchemaViolation> validate(Object? value, {String path = r'$'}) {
    List<SchemaViolation>? closest;
    int distance(List<SchemaViolation> found) =>
        found.length + (found.any((v) => v.path == path) ? options.length : 0);
    for (final option in options) {
      final violations = option.validate(value, path: path);
      if (violations.isEmpty) return const [];
      if (closest == null || distance(violations) < distance(closest)) {
        closest = violations;
      }
    }
    return closest ?? _expect(false, path, 'one of no options');
  }
}
