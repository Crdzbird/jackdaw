import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/catalog/ui_component_definition.dart';
import 'package:jackdaw/src/ui/schema/ui_tree_children.dart';
import 'package:jackdaw/src/ui/schema/ui_value_schemas.dart';

/// The schema of a screen written as a tree for [catalog]: a `surfaceId`,
/// a `root` component and a `dataModel`, where every container holds its
/// children inside it, at most [depth] levels deep. Components carry no
/// ids, so a reference cannot dangle and the tree cannot loop. Local
/// models read [guide] in place of the schema of the root.
ObjectSchema uiTreeSchema(
  UiCatalog catalog,
  UiValueSchemas values, {
  required int depth,
  required int callDepth,
  required ObjectSchema accessibility,
  required String guide,
}) {
  final leaves = <String, ObjectSchema>{};
  final levels = <int, UnionSchema>{};
  ObjectSchema variant(UiComponentDefinition c, ObjectSchema props) =>
      ObjectSchema(
        properties: {...props.properties, 'accessibility': accessibility},
        required: props.required,
        description: c.description,
      );
  UnionSchema level(int d) => levels[d] ??= UnionSchema(
    discriminator: 'component',
    variants: {
      for (final c in catalog.components)
        if (!uiNests(c))
          c.name: leaves[c.name] ??= variant(
            c,
            values.resolve(c.props, callDepth) as ObjectSchema,
          ),
      for (final c in catalog.components)
        if (uiNests(c) && d > 0)
          c.name: variant(
            c,
            uiHolding(c.props, level(d - 1), values, callDepth),
          ),
    },
    description: 'A component; containers hold their children inside.',
  );
  return ObjectSchema(
    properties: {
      'surfaceId': const Schema.string(description: 'A name for the screen.'),
      'root': Schema.summarized(level(depth), summary: guide),
      'dataModel': const Schema.map(
        values: Schema.raw({}),
        description: 'The data the components bind to.',
      ),
    },
    required: ['surfaceId', 'root'],
    description: 'A screen as a tree of components.',
  );
}
