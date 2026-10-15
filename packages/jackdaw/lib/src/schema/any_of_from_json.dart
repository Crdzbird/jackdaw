import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/schema/schema_from_json.dart';

/// Reads an `anyOf` document. When every option is an object schema and
/// all of them share a required property that is a string enum of one
/// distinct value, it becomes a [UnionSchema]; when every option is a
/// typed schema, an [AnyOfSchema]; otherwise it is kept whole as a
/// [RawSchema].
Schema anyOfFromJson(Map<String, Object?> json, String? description) {
  final options = json['anyOf'];
  if (options is! List || options.isEmpty) return RawSchema(json);
  final schemas = [
    for (final option in options)
      if (option is Map<String, Object?>) schemaFromJson(option),
  ];
  if (schemas.length != options.length || schemas.any((s) => s is RawSchema)) {
    return RawSchema(json);
  }
  final objects = schemas.whereType<ObjectSchema>().toList();
  final tag = objects.length == schemas.length
      ? objects.first.properties.keys
            .where((key) => _tags(objects, key) != null)
            .firstOrNull
      : null;
  if (tag == null) return AnyOfSchema(schemas, description: description);
  final tags = _tags(objects, tag)!;
  return UnionSchema(
    discriminator: tag,
    variants: {
      for (var i = 0; i < objects.length; i++)
        tags[i]: _without(objects[i], tag),
    },
    description: description,
  );
}

List<String>? _tags(List<ObjectSchema> objects, String key) {
  final tags = [
    for (final object in objects)
      if (object.required.contains(key))
        if (object.properties[key] case StringSchema(
          enumValues: [final String value],
        ))
          value,
  ];
  if (tags.length != objects.length) return null;
  if (tags.toSet().length != tags.length) return null;
  return tags;
}

ObjectSchema _without(ObjectSchema object, String key) => ObjectSchema(
  properties: {...object.properties}..remove(key),
  required: [...object.required.where((k) => k != key)],
  additionalProperties: object.additionalProperties,
  description: object.description,
);
