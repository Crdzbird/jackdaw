part of 'schema.dart';

/// Schema for JSON numbers without a fractional part.
final class IntegerSchema extends Schema {
  /// Creates an integer schema.
  const factory({String? description}) = IntegerSchema._;

  const new _({super.description}) : super._();

  @override
  Map<String, Object?> toJson() => _base('integer');

  @override
  List<SchemaViolation> validate(Object? value, {String path = r'$'}) =>
      _expect(
        value is num && value.isFinite && value % 1 == 0,
        path,
        'an integer',
      );
}
