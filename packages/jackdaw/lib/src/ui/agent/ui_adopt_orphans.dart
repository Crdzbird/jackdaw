import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/surface/ui_child_refs.dart';
import 'package:jackdaw/src/ui/surface/ui_component.dart';
import 'package:jackdaw/src/ui/surface/ui_message_parts.dart';

/// [messages] with each new surface's unreferenced components added to the
/// end of its root's children, in the order they were sent, when the root
/// lists its children by id.
///
/// Small models often define a component and forget to list it, and A2UI
/// does not show a component nothing refers to. Only `createSurface`
/// messages change, since an update may refer to components sent before.
List<Object?> uiAdoptOrphans(List<Object?> messages, UiCatalog catalog) => [
  for (final message in messages) _adopt(message, catalog),
];

Object? _adopt(Object? message, UiCatalog catalog) {
  if (uiMessageParts(message) case (
    'createSurface',
    {'components': final List<Object?> list} && final body,
  )) {
    final components = [
      for (final c in list.whereType<Map<String, Object?>>())
        if (c case {'id': String(), 'component': String()})
          UiComponent.fromJson(c),
    ];
    final root = components.where((c) => c.id == 'root').firstOrNull;
    final children = root?.props['children'];
    if (root == null || children is! List<Object?>) return message;
    final referenced = {
      for (final c in components)
        if (catalog.component(c.type) case final definition?)
          for (final (_, id) in uiChildRefs(definition.props, c.props)) id,
    };
    final orphans = [
      for (final c in components)
        if (c.id != 'root' && !referenced.contains(c.id)) c.id,
    ];
    if (orphans.isEmpty) return message;
    return {
      ...message! as Map<String, Object?>,
      'createSurface': {
        ...body,
        'components': [
          for (final item in list)
            _withChildren(item, [...children, ...orphans]),
        ],
      },
    };
  }
  return message;
}

Object? _withChildren(Object? item, List<Object?> children) => switch (item) {
  {'id': 'root'} && final Map<String, Object?> json => {
    ...json,
    'children': children,
  },
  _ => item,
};
