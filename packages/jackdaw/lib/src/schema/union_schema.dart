part of 'schema.dart';

/// Schema for JSON objects of several kinds, told apart by a tag.
///
/// Each value is an object whose [discriminator] property names one of
/// the [variants], and the rest of the object must match that variant.
/// It serializes as `anyOf` with the tag as a one-value enum, which every
/// provider accepts, and constrained decoding emits exactly one variant.
final class UnionSchema extends Schema {
  /// Creates a union of [variants] keyed by the value of [discriminator].
  ///
  /// The discriminator is added to each variant as its first, required
  /// property; a property of the same name in a variant is replaced.
  const factory({
    required String discriminator,
    required Map<String, ObjectSchema> variants,
    String? description,
  }) = UnionSchema._;

  const new _({
    required this.discriminator,
    required this.variants,
    super.description,
  }) : super._();

  /// The property whose value names the variant.
  final String discriminator;

  /// The object schema of each variant, keyed by its tag.
  final Map<String, ObjectSchema> variants;

  /// Each variant with the discriminator added, keyed by its tag.
  Map<String, ObjectSchema> get alternatives => {
    for (final MapEntry(:key, :value) in variants.entries)
      key: _tagged(key, value),
  };

  @override
  Map<String, Object?> toJson() => {
    if (description != null) 'description': description,
    'anyOf': [for (final schema in alternatives.values) schema.toJson()],
  };

  @override
  List<SchemaViolation> validate(Object? value, {String path = r'$'}) {
    if (value is! Map) return _expect(false, path, 'an object');
    final tag = value[discriminator];
    if (tag is! String || !variants.containsKey(tag)) {
      return _expect(
        false,
        '$path.$discriminator',
        'one of ${variants.keys.join(', ')}',
      );
    }
    return _tagged(tag, variants[tag]!).validate(value, path: path);
  }

  ObjectSchema _tagged(String tag, ObjectSchema schema) => ObjectSchema(
    properties: {
      discriminator: StringSchema(enumValues: [tag]),
      for (final MapEntry(:key, :value) in schema.properties.entries)
        if (key != discriminator) key: value,
    },
    required: [
      discriminator,
      ...schema.required.where((key) => key != discriminator),
    ],
    additionalProperties: schema.additionalProperties,
    description: schema.description,
  );
}
