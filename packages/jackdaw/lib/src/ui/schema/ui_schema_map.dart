import 'package:jackdaw/src/schema/schema.dart';

/// [schema] with every nested schema for which [replace] returns a schema
/// swapped for it, rebuilding the objects, arrays, maps, unions and anyOf
/// schemas around it. Each schema is mapped once, so shared parts stay
/// shared.
Schema uiMapSchema(Schema schema, Schema? Function(Schema node) replace) {
  final done = Map<Schema, Schema>.identity();
  Schema map(Schema node) => done[node] ??=
      replace(node) ??
      switch (node) {
        ObjectSchema() => _object(node, map),
        ArraySchema() => ArraySchema(
          items: map(node.items),
          prefixItems: [for (final item in node.prefixItems) map(item)],
          minItems: node.minItems,
          maxItems: node.maxItems,
          description: node.description,
        ),
        MapSchema(:final values, :final description) => MapSchema(
          values: map(values),
          description: description,
        ),
        AnyOfSchema(:final options, :final description) => AnyOfSchema([
          for (final option in options) map(option),
        ], description: description),
        UnionSchema(
          :final discriminator,
          :final variants,
          :final description,
        ) =>
          UnionSchema(
            discriminator: discriminator,
            variants: {
              for (final MapEntry(:key, :value) in variants.entries)
                key: _object(value, map),
            },
            description: description,
          ),
        _ => node,
      };
  return map(schema);
}

ObjectSchema _object(ObjectSchema schema, Schema Function(Schema) map) =>
    ObjectSchema(
      properties: {
        for (final MapEntry(:key, :value) in schema.properties.entries)
          key: map(value),
      },
      required: schema.required,
      additionalProperties: schema.additionalProperties,
      description: schema.description,
    );
