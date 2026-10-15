import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/schema/schema_from_json.dart';

/// Reads an `anyOf` document as a [UnionSchema] when every alternative is
/// an object schema and all of them share a required property that is a
/// string enum of one distinct value. Any other document is kept whole as
/// a [RawSchema].
Schema unionFromJson(Map<String, Object?> json, String? description) {
  final options = json['anyOf'];
  if (options is! List || options.isEmpty) return RawSchema(json);
  final objects = [
    for (final option in options)
      if (option is Map<String, Object?>) schemaFromJson(option),
  ].whereType<ObjectSchema>().toList();
  if (objects.length != options.length) return RawSchema(json);
  final tag = objects.first.properties.keys
      .where((key) => _tags(objects, key) != null)
      .firstOrNull;
  if (tag == null) return RawSchema(json);
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
