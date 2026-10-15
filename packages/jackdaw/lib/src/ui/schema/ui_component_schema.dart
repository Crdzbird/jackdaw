import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/catalog/ui_component_definition.dart';
import 'package:jackdaw/src/ui/catalog/ui_type.dart';
import 'package:jackdaw/src/ui/schema/ui_value_schemas.dart';

const Schema _id = Schema.string(description: 'A unique id; root for the top.');

const Schema _rootId = Schema.string(enumValues: ['root']);

/// The schema of one instance of [definition], whose resolved props are
/// [props]: its id, its props and its [accessibility] attributes. A [root]
/// component must have the id `root`.
ObjectSchema uiComponentSchema(
  UiComponentDefinition definition,
  ObjectSchema props,
  ObjectSchema accessibility, {
  bool root = false,
}) => ObjectSchema(
  properties: {
    'id': root ? _rootId : _id,
    ...props.properties,
    'accessibility': accessibility,
  },
  required: ['id', ...props.required],
  description: definition.description,
);

/// The accessibility attributes every component may carry, with values
/// resolved by [values] at [depth].
ObjectSchema uiAccessibilitySchema(UiValueSchemas values, int depth) =>
    ObjectSchema(
      properties: {
        'label': values.type(UiType.dynamicString, depth),
        'live': const Schema.string(enumValues: ['off', 'polite', 'assertive']),
        'hidden': values.type(UiType.dynamicBoolean, depth),
      },
      description: 'What a screen reader announces.',
    );

/// One component of [catalog] told apart by its `component` name, with
/// props resolved by [values] at [depth]; a [root] component has the id
/// `root`.
UnionSchema uiComponentUnion(
  UiCatalog catalog,
  UiValueSchemas values,
  int depth,
  ObjectSchema accessibility, {
  bool root = false,
}) => UnionSchema(
  discriminator: 'component',
  variants: {
    for (final c in catalog.components)
      c.name: uiComponentSchema(
        c,
        values.resolve(c.props, depth) as ObjectSchema,
        accessibility,
        root: root,
      ),
  },
  description: 'A component on a surface.',
);
