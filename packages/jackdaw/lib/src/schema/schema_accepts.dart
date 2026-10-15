part of 'schema.dart';

/// A quick yes or no check of a value against a schema.
extension SchemaAccepts on Schema {
  /// Whether [value] matches this schema: the same answer as
  /// `validate(value).isEmpty`, without building the path and message of
  /// each violation, so it is much faster on values that match. Call
  /// `validate` to learn what is wrong.
  bool accepts(Object? value) => switch (this) {
    StringSchema(:final enumValues) =>
      value is String && (enumValues == null || enumValues.contains(value)),
    NumberSchema() => value is num,
    IntegerSchema() => value is num && value.isFinite && value % 1 == 0,
    BooleanSchema() => value is bool,
    RawSchema() => true,
    SummarizedSchema(:final schema) => schema.accepts(value),
    AnyOfSchema(:final options) => options.any((o) => o.accepts(value)),
    MapSchema(:final values) =>
      value is Map && _isObject(value) && value.values.every(values.accepts),
    ObjectSchema() => _object(this as ObjectSchema, value),
    ArraySchema() => _array(this as ArraySchema, value),
    UnionSchema(:final discriminator, :final alternatives) =>
      value is Map &&
          switch (value[discriminator]) {
            final String tag => alternatives[tag]?.accepts(value) ?? false,
            _ => false,
          },
  };

  /// What is wrong with [value], as `validate` says, but checked with
  /// [accepts] first so a matching value costs no more than that.
  List<SchemaViolation> check(Object? value) =>
      accepts(value) ? const [] : validate(value);
}

bool _isObject(Object? value) =>
    value is Map && value.keys.every((key) => key is String);

bool _object(ObjectSchema schema, Object? value) {
  if (value is! Map || !_isObject(value)) return false;
  if (!schema.required.every(value.containsKey)) return false;
  for (final MapEntry(:key, value: item) in value.entries) {
    final property = schema.properties[key];
    if (property == null && !schema.additionalProperties) return false;
    if (property != null && !property.accepts(item)) return false;
  }
  return true;
}

bool _array(ArraySchema schema, Object? value) {
  if (value is! List<Object?>) return false;
  if (value.length < schema.minItems) return false;
  if (value.length > (schema.maxItems ?? value.length)) return false;
  for (var i = 0; i < value.length; i++) {
    final item = i < schema.prefixItems.length
        ? schema.prefixItems[i]
        : schema.items;
    if (!item.accepts(value[i])) return false;
  }
  return true;
}
