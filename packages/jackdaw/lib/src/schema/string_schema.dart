part of 'schema.dart';

/// Schema for JSON strings.
final class StringSchema extends Schema {
  /// Creates a string schema, optionally limited to [enumValues].
  const factory({List<String>? enumValues, String? description}) =
      StringSchema._;

  const new _({this.enumValues, super.description}) : super._();

  /// The only accepted values, when set.
  final List<String>? enumValues;

  @override
  Map<String, Object?> toJson() => {
    ..._base('string'),
    if (enumValues != null) 'enum': enumValues,
  };

  @override
  List<SchemaViolation> validate(Object? value, {String path = r'$'}) {
    final allowed = enumValues;
    if (value is! String) return _expect(false, path, 'a string');
    if (allowed == null) return const [];
    return _expect(
      allowed.contains(value),
      path,
      'one of ${allowed.join(', ')}',
    );
  }
}
