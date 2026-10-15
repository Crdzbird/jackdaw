part of 'schema.dart';

/// Schema for JSON objects with any keys whose values all match [values],
/// such as a map of names to bound data.
final class MapSchema extends Schema {
  /// Creates a schema for objects whose every value matches [values].
  const factory({required Schema values, String? description}) = MapSchema._;

  const new _({required this.values, super.description}) : super._();

  /// Schema every value must match.
  final Schema values;

  @override
  Map<String, Object?> toJsonWith(SchemaEncoder child) => {
    ..._base('object'),
    'additionalProperties': child(values),
  };

  @override
  List<SchemaViolation> validate(Object? value, {String path = r'$'}) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      return _expect(false, path, 'an object');
    }
    return [
      for (final MapEntry(:key, value: item) in value.entries)
        ...values.validate(item, path: '$path.$key'),
    ];
  }
}
