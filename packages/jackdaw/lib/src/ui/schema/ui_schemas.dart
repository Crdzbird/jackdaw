import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/catalog/ui_component_definition.dart';
import 'package:jackdaw/src/ui/catalog/ui_type.dart';
import 'package:jackdaw/src/ui/schema/ui_catalog_guide.dart';
import 'package:jackdaw/src/ui/schema/ui_message_schema.dart';
import 'package:jackdaw/src/ui/schema/ui_value_schemas.dart';

/// The schemas of A2UI v1.0 components and messages for one catalog.
///
/// They validate what a model or another agent sends, and compile with
/// the GBNF compiler into grammars that hold a local model to components and
/// functions the catalog has, with props that match.
final class UiSchemas {
  /// Builds the schemas for [catalog], allowing [callDepth] levels of
  /// function calls nested in a value and [maxComponents] components in
  /// one message.
  factory(UiCatalog catalog, {int callDepth, int maxComponents}) = UiSchemas._;

  new _(this.catalog, {this.callDepth = 2, this.maxComponents = 40})
    : values = UiValueSchemas(catalog);

  /// The catalog the schemas describe.
  final UiCatalog catalog;

  /// How deeply function calls may nest inside a value.
  final int callDepth;

  /// The most components one message may carry.
  final int maxComponents;

  /// The resolver of the catalog's common type references.
  final UiValueSchemas values;

  /// One component on a surface, told apart by its `component` name.
  late final UnionSchema component = UnionSchema(
    discriminator: 'component',
    variants: {for (final c in catalog.components) c.name: _component(c)},
    description: 'A component on a surface.',
  );

  /// One agent-to-renderer message.
  late final Schema message = uiMessageSchema(
    catalog.id,
    Schema.array(
      items: component,
      minItems: 1,
      maxItems: maxComponents,
      description: 'The components; one of them has the id root.',
    ),
  );

  /// A list of agent-to-renderer messages, applied in order.
  late final Schema messages = Schema.array(
    items: message,
    minItems: 1,
    maxItems: 4,
    description: 'A2UI v1.0 messages, applied in order.',
  );

  /// [messages], described to local models by the catalog guide instead
  /// of its full schema, which would not fit a small model's context.
  late final Schema reply = Schema.summarized(
    messages,
    summary: uiCatalogGuide(catalog),
  );

  ObjectSchema _component(UiComponentDefinition definition) {
    final props = values.resolve(definition.props, callDepth) as ObjectSchema;
    return ObjectSchema(
      properties: {
        'id': const Schema.string(
          description: 'A unique id; root for the top.',
        ),
        ...props.properties,
        'accessibility': _accessibility,
      },
      required: ['id', ...props.required],
      description: definition.description,
    );
  }

  late final ObjectSchema _accessibility = ObjectSchema(
    properties: {
      'label': values.type(UiType.dynamicString, callDepth),
      'live': const Schema.string(enumValues: ['off', 'polite', 'assertive']),
      'hidden': values.type(UiType.dynamicBoolean, callDepth),
    },
    description: 'What a screen reader announces.',
  );
}
