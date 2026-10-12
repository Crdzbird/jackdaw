part of 'schema.dart';

/// Schema for JSON objects.
final class ObjectSchema extends Schema {
  /// Creates an object schema with named [properties].
  ///
  /// Keys listed in [required] must be present. Keys not in [properties]
  /// are rejected unless [additionalProperties] is true.
  const factory({
    required Map<String, Schema> properties,
    List<String> required,
    bool additionalProperties,
    String? description,
  }) = ObjectSchema._;

  const new _({
    required this.properties,
    this.required = const [],
    this.additionalProperties = false,
    super.description,
  }) : super._();

  /// Schemas of the known keys.
  final Map<String, Schema> properties;

  /// Keys that must be present.
  final List<String> required;

  /// Whether keys outside [properties] are accepted.
  final bool additionalProperties;

  @override
  Map<String, Object?> toJson() => {
    ..._base('object'),
    'properties': {
      for (final entry in properties.entries) entry.key: entry.value.toJson(),
    },
    'required': required,
    'additionalProperties': additionalProperties,
  };

  @override
  List<SchemaViolation> validate(Object? value, {String path = r'$'}) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      return _expect(false, path, 'an object');
    }
    return [
      for (final key in required)
        if (!value.containsKey(key))
          SchemaViolation('$path.$key', 'is required'),
      for (final key in value.keys)
        if (!additionalProperties && !properties.containsKey(key))
          SchemaViolation('$path.$key', 'is not allowed'),
      for (final MapEntry(:key, value: schema) in properties.entries)
        if (value.containsKey(key))
          ...schema.validate(value[key], path: '$path.$key'),
    ];
  }
}
