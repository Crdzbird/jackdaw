part of 'schema.dart';

/// Schema for JSON booleans.
final class BooleanSchema extends Schema {
  /// Creates a boolean schema.
  const factory({String? description}) = BooleanSchema._;

  const new _({super.description}) : super._();

  @override
  Map<String, Object?> toJson() => _base('boolean');

  @override
  List<SchemaViolation> validate(Object? value, {String path = r'$'}) =>
      _expect(value is bool, path, 'a boolean');
}
