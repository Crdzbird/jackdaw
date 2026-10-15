import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/schema/ui_catalog_guide.dart';
import 'package:jackdaw/src/ui/schema/ui_component_schema.dart';
import 'package:jackdaw/src/ui/schema/ui_format.dart';
import 'package:jackdaw/src/ui/schema/ui_message_schema.dart';
import 'package:jackdaw/src/ui/schema/ui_reply_schema.dart';
import 'package:jackdaw/src/ui/schema/ui_tree_schema.dart';
import 'package:jackdaw/src/ui/schema/ui_value_schemas.dart';

/// The schemas of A2UI v1.0 components and messages for one catalog.
///
/// They validate what a model or another agent sends, and compile with
/// the GBNF compiler into grammars that hold a local model to components and
/// functions the catalog has, with props that match.
final class UiSchemas {
  /// Builds the schemas for [catalog], allowing [callDepth] levels of
  /// function calls nested in a value, [maxComponents] components in one
  /// message and [treeDepth] levels of nesting in a tree.
  factory(
    UiCatalog catalog, {
    int callDepth,
    int maxComponents,
    int treeDepth,
  }) = UiSchemas._;

  new _(
    this.catalog, {
    this.callDepth = 2,
    this.maxComponents = 40,
    this.treeDepth = 6,
  }) : values = UiValueSchemas(catalog);

  /// The catalog the schemas describe.
  final UiCatalog catalog;

  /// How deeply function calls may nest inside a value.
  final int callDepth;

  /// The most components one message may carry.
  final int maxComponents;

  /// How deeply components may nest in a [tree].
  final int treeDepth;

  /// The resolver of the catalog's common type references.
  final UiValueSchemas values;

  /// One component on a surface, told apart by its `component` name.
  late final UnionSchema component = _union(values);

  /// One agent-to-renderer message.
  late final Schema message = uiMessageSchema(catalog.id, _components);

  /// A list of agent-to-renderer messages, applied in order.
  late final Schema messages = Schema.array(
    items: message,
    minItems: 1,
    maxItems: 4,
    description: 'A2UI v1.0 messages, applied in order.',
  );

  /// A model's answer as messages: only the first may create a surface,
  /// root first. Local models read the catalog guide, not the schema.
  late final Schema reply = uiReplySchema(
    catalog,
    created: _list(component, first: _union(values, root: true)),
    updates: uiUpdateMessages(_components),
  );

  /// A whole screen as a tree, which small models get right more often
  /// than [reply]; `uiTreeMessages` turns it into A2UI messages.
  late final ObjectSchema tree = uiTreeSchema(
    catalog,
    values,
    depth: treeDepth,
    callDepth: callDepth,
    accessibility: _accessibility,
    guide: uiCatalogGuide(catalog, format: UiFormat.tree),
  );

  late final Schema _components = _list(component);

  Schema _list(Schema items, {Schema? first}) => Schema.array(
    items: items,
    prefixItems: [?first],
    minItems: 1,
    maxItems: maxComponents,
    description: 'The components; one of them has the id root.',
  );

  UnionSchema _union(UiValueSchemas from, {bool root = false}) =>
      uiComponentUnion(catalog, from, callDepth, _accessibility, root: root);

  late final ObjectSchema _accessibility = uiAccessibilitySchema(
    values,
    callDepth,
  );
}
