import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/catalog/ui_type.dart';
import 'package:jackdaw/src/ui/schema/ui_message_schema.dart';

/// The A2UI v1.0 messages for a screen written as a tree, as `UiSchemas`
/// `tree` describes: one `createSurface` with every component in a flat
/// list and children referred to by id.
///
/// The root gets the id `root` and the others an id made from their name
/// and their place, such as `text3`. A template becomes a `componentId`
/// and a `path`. Props that are not children are copied as they are.
List<Object?> uiTreeMessages(Map<String, Object?> tree, UiCatalog catalog) {
  final components = <Map<String, Object?>>[];
  final counts = <String, int>{};
  String add(Object? node, [String? id]) {
    final component = node is Map<String, Object?>
        ? node
        : const <String, Object?>{};
    final type = component['component'] is String
        ? component['component']! as String
        : 'Unknown';
    final number = counts[type] = (counts[type] ?? 0) + 1;
    final name = id ?? '${type[0].toLowerCase()}${type.substring(1)}$number';
    final at = components.length;
    components.add(const {});
    final props = catalog.component(type)?.props.properties ?? const {};
    components[at] = {
      'id': name,
      for (final MapEntry(:key, :value) in component.entries)
        key: _flatten(props[key], value, add),
    };
    return name;
  }

  add(tree['root'], 'root');
  return [
    {
      'version': uiProtocolVersion,
      'createSurface': {
        'surfaceId': tree['surfaceId'],
        'components': components,
        if (tree['dataModel'] case final Object data) 'dataModel': data,
      },
    },
  ];
}

Object? _flatten(
  Schema? schema,
  Object? value,
  String Function(Object? node, [String? id]) add,
) => switch ((schema == null ? null : UiType.of(schema), schema, value)) {
  (UiType.child, _, final Map<String, Object?> node) => add(node),
  (UiType.childList, _, final List<Object?> nodes) => [
    for (final node in nodes) add(node),
  ],
  (UiType.childList, _, {'template': final Object node, 'path': final path}) =>
    {'componentId': add(node), 'path': path},
  (_, ObjectSchema(:final properties), final Map<String, Object?> map) => {
    for (final MapEntry(:key, :value) in map.entries)
      key: _flatten(properties[key], value, add),
  },
  (_, ArraySchema(:final items), final List<Object?> list) => [
    for (final item in list) _flatten(items, item, add),
  ],
  _ => value,
};
