import 'package:jackdaw/src/schema/any_of_from_json.dart';
import 'package:jackdaw/src/schema/schema.dart';

const Set<String> _ignored = {r'$schema', r'$comment', 'title', 'examples'};

/// Reads a JSON Schema document, such as an MCP tool's `inputSchema`.
///
/// A document becomes a typed schema only when every keyword in it is
/// understood, so no constraint is dropped. Any other document, such as one
/// using `$ref` or `minLength`, is kept whole as a [RawSchema]. An object
/// whose `additionalProperties` is a typed schema becomes a [MapSchema]. An
/// `anyOf` of typed schemas becomes an [AnyOfSchema], or a [UnionSchema]
/// when its options are objects tagged by a shared one-value enum property.
/// A missing `additionalProperties` means true, as in JSON Schema.
Schema schemaFromJson(Map<String, Object?> json) {
  final keys = json.keys.where((k) => !_ignored.contains(k)).toSet();
  final description = json['description'];
  if (description != null && description is! String) return RawSchema(json);
  final text = description as String?;
  bool only(Set<String> allowed) =>
      keys.difference({'type', 'description', ...allowed}).isEmpty;
  return switch (json['type']) {
    'string' when only({'enum'}) => _string(json, text),
    'integer' when only({}) => IntegerSchema(description: text),
    'number' when only({}) => NumberSchema(description: text),
    'boolean' when only({}) => BooleanSchema(description: text),
    'array'
        when only({'items', 'minItems', 'maxItems'}) &&
            json['items'] is Map<String, Object?> =>
      _array(json, text),
    'object'
        when only({'additionalProperties'}) &&
            json['additionalProperties'] is Map<String, Object?> =>
      _map(json, text),
    'object' when only({'properties', 'required', 'additionalProperties'}) =>
      _object(json, text),
    null when only({'anyOf'}) => anyOfFromJson(json, text),
    _ => RawSchema(json),
  };
}

Schema _string(Map<String, Object?> json, String? text) {
  final values = json['enum'];
  if (values == null) return StringSchema(description: text);
  if (values is! List || values.any((v) => v is! String)) {
    return RawSchema(json);
  }
  return StringSchema(enumValues: values.cast<String>(), description: text);
}

Schema _array(Map<String, Object?> json, String? text) {
  final min = json['minItems'] ?? 0;
  final max = json['maxItems'];
  if (min is! int || min < 0 || (max != null && max is! int)) {
    return RawSchema(json);
  }
  final items = json['items']! as Map<String, Object?>;
  return ArraySchema(
    items: schemaFromJson(items),
    minItems: min,
    maxItems: max as int?,
    description: text,
  );
}

Schema _map(Map<String, Object?> json, String? text) => switch (schemaFromJson(
  json['additionalProperties']! as Map<String, Object?>,
)) {
  RawSchema() => RawSchema(json),
  final values => MapSchema(values: values, description: text),
};

Schema _object(Map<String, Object?> json, String? text) {
  final properties = json['properties'] ?? const <String, Object?>{};
  final required = json['required'] ?? const <Object?>[];
  final extra = json['additionalProperties'] ?? true;
  if (properties is! Map<String, Object?> ||
      properties.values.any((p) => p is! Map<String, Object?>) ||
      required is! List ||
      required.any((r) => r is! String) ||
      extra is! bool) {
    return RawSchema(json);
  }
  return ObjectSchema(
    properties: {
      for (final MapEntry(:key, :value) in properties.entries)
        key: schemaFromJson(value! as Map<String, Object?>),
    },
    required: required.cast<String>(),
    additionalProperties: extra,
    description: text,
  );
}
