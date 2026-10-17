part of 'schema.dart';

/// A quick yes or no check of a value against a schema.
extension SchemaAccepts on Schema {
  /// Whether [value] matches this schema: the same answer as
  /// `validate(value).isEmpty`, without building the path and message of
  /// each violation, so it is much faster on values that match. Call
  /// `validate` to learn what is wrong.
  bool accepts(Object? value) => switch (this) {
    ObjectSchema() => _object(this as ObjectSchema, value),
    StringSchema(:final enumValues) =>
      value is String && (enumValues == null || enumValues.contains(value)),
    AnyOfSchema(:final options) => _any(options, value),
    UnionSchema(:final discriminator, :final alternatives) =>
      value is Map &&
          switch (value[discriminator]) {
            final String tag => alternatives[tag]?.accepts(value) ?? false,
            _ => false,
          },
    NumberSchema() => value is num,
    IntegerSchema() => value is num && value.isFinite && value % 1 == 0,
    BooleanSchema() => value is bool,
    RawSchema() => true,
    SummarizedSchema(:final schema) => schema.accepts(value),
    MapSchema(:final values) => _map(values, value),
    ArraySchema() => _array(this as ArraySchema, value),
  };

  /// What is wrong with [value], as `validate` says, but checked with
  /// [accepts] first so a matching value costs no more than that.
  List<SchemaViolation> check(Object? value) =>
      accepts(value) ? const [] : validate(value);
}

bool _any(List<Schema> options, Object? value) {
  for (final option in options) {
    if (option.accepts(value)) return true;
  }
  return false;
}

bool _map(Schema values, Object? value) {
  if (value is! Map) return false;
  for (final MapEntry(:key, value: item) in value.entries) {
    if (key is! String || !values.accepts(item)) return false;
  }
  return true;
}

bool _object(ObjectSchema schema, Object? value) {
  if (value is! Map) return false;
  for (final key in schema.required) {
    if (!value.containsKey(key)) return false;
  }
  for (final MapEntry(:key, value: item) in value.entries) {
    if (key is! String) return false;
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
