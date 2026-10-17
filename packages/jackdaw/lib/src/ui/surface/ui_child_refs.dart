import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/catalog/ui_type.dart';

/// The child ids [props] refer to, each with the JSON Pointer of the prop
/// that holds it, found by walking [schema], the props schema of the
/// component's catalog entry.
///
/// Children are props of the common types Child and ChildList, at any
/// depth, such as the `child` of each tab in a Tabs component; a template
/// counts as one child.
List<(String, String)> uiChildRefs(ObjectSchema schema, Object? props) {
  if (!(_holdsChildren[schema] ??= _mayHold(schema))) return const [];
  final refs = <(String, String)>[];
  void walk(Schema node, Object? value, String path) {
    switch ((UiType.of(node), node, value)) {
      case (UiType.child, _, final String id):
        refs.add((path, id));
      case (UiType.childList, _, final List<Object?> ids):
        for (final (i, id) in ids.indexed) {
          if (id is String) refs.add(('$path/$i', id));
        }
      case (UiType.childList, _, {'componentId': final String id}):
        refs.add(('$path/componentId', id));
      case (_, ObjectSchema(:final properties), final Map<String, Object?> map):
        for (final MapEntry(:key, value: child) in properties.entries) {
          if (map.containsKey(key)) walk(child, map[key], '$path/$key');
        }
      case (_, ArraySchema(:final items), final List<Object?> list):
        for (final (i, item) in list.indexed) {
          walk(items, item, '$path/$i');
        }
    }
  }

  walk(schema, props, '');
  return refs;
}

final Expando<bool> _holdsChildren = Expando();

bool _mayHold(Schema schema) => switch ((UiType.of(schema), schema)) {
  (UiType.child || UiType.childList, _) => true,
  (_, ObjectSchema(:final properties)) => properties.values.any(_mayHold),
  (_, ArraySchema(:final items)) => _mayHold(items),
  _ => false,
};
