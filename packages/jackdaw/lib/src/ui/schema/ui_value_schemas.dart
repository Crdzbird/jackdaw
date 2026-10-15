import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/catalog/ui_type.dart';
import 'package:jackdaw/src/ui/schema/ui_call_schema.dart';
import 'package:jackdaw/src/ui/schema/ui_common_schemas.dart';

/// Resolves the A2UI common type references of a catalog into schemas
/// that validate values and constrain decoding.
///
/// Calls may nest: a value at depth `d` may be a call whose arguments are
/// at depth `d - 1`, and a value at depth 0 is a literal or a binding. The
/// same schema at the same depth always resolves to the same instance, so
/// a grammar shares its rules.
final class UiValueSchemas {
  /// Creates the resolver for [catalog].
  factory(UiCatalog catalog) = UiValueSchemas._;

  new _(this.catalog);

  /// The catalog whose functions values may call.
  final UiCatalog catalog;

  final Map<(Schema, int), Schema> _resolved = {};
  final Map<(UiType, int), Schema> _types = {};
  final Map<(String, int), Schema?> _calls = {};

  /// [schema] with every common type reference replaced by its schema,
  /// allowing [depth] levels of nested calls.
  Schema resolve(Schema schema, int depth) {
    final key = (schema, depth);
    return _resolved[key] ??= switch (schema) {
      RawSchema() => switch (UiType.of(schema)) {
        final common? => type(common, depth),
        null => schema,
      },
      ObjectSchema() => _object(schema, depth),
      ArraySchema() => ArraySchema(
        items: resolve(schema.items, depth),
        prefixItems: [for (final p in schema.prefixItems) resolve(p, depth)],
        minItems: schema.minItems,
        maxItems: schema.maxItems,
        description: schema.description,
      ),
      MapSchema(:final values, :final description) => MapSchema(
        values: resolve(values, depth),
        description: description,
      ),
      AnyOfSchema(:final options, :final description) => AnyOfSchema([
        for (final option in options) resolve(option, depth),
      ], description: description),
      UnionSchema(:final discriminator, :final variants, :final description) =>
        UnionSchema(
          discriminator: discriminator,
          variants: {
            for (final MapEntry(:key, :value) in variants.entries)
              key: _object(value, depth),
          },
          description: description,
        ),
      _ => schema,
    };
  }

  /// The schema of [type] allowing [depth] levels of nested calls.
  Schema type(UiType type, int depth) =>
      _types[(type, depth)] ??= uiCommonSchema(type, depth, this);

  /// The schema of a call returning a value of [kind], one of the keys of
  /// [uiReturnsFor], with arguments at [depth] minus one, or `null` at
  /// depth 0 or when the catalog has no such function.
  Schema? call(String kind, int depth) => depth <= 0
      ? null
      : _calls.putIfAbsent(
          (kind, depth),
          () => uiCallSchema(
            catalog,
            uiReturnsFor[kind]!,
            (args) => _object(args, depth - 1),
          ),
        );

  ObjectSchema _object(ObjectSchema schema, int depth) =>
      (_resolved[(schema, depth)] ??= ObjectSchema(
            properties: {
              for (final MapEntry(:key, :value) in schema.properties.entries)
                key: resolve(value, depth),
            },
            required: schema.required,
            additionalProperties: schema.additionalProperties,
            description: schema.description,
          ))
          as ObjectSchema;
}
