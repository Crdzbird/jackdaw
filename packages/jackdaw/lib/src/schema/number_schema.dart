part of 'schema.dart';

/// Schema for any JSON number.
final class NumberSchema extends Schema {
  /// Creates a number schema.
  const factory({String? description}) = NumberSchema._;

  const new _({super.description}) : super._();

  @override
  Map<String, Object?> toJson() => _base('number');

  @override
  List<SchemaViolation> validate(Object? value, {String path = r'$'}) =>
      _expect(value is num, path, 'a number');
}
