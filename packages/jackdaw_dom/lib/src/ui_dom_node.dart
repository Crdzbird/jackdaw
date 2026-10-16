import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_dom/src/ui_dom_controller.dart';
import 'package:web/web.dart' as web;

/// One component being drawn: its props read in its scope, its children,
/// and the ways it writes data and triggers actions.
final class UiDomNode {
  /// Creates the node of [component] on [surface] in [scope], whose
  /// children are drawn by [draw].
  const factory({
    required UiDomController controller,
    required UiSurface surface,
    required UiComponent component,
    required UiScope scope,
    required web.HTMLElement Function(UiDomNode node) draw,
    List<String> ancestors,
  }) = UiDomNode._;

  const new _({
    required this.controller,
    required this.surface,
    required this.component,
    required this.scope,
    required this.draw,
    this.ancestors = const [],
  });

  /// The controller the surface belongs to.
  final UiDomController controller;

  /// The surface being drawn.
  final UiSurface surface;

  /// The component this node draws.
  final UiComponent component;

  /// Where its bindings are read: the root, or a list item of a template.
  final UiScope scope;

  /// Draws a node of this surface.
  final web.HTMLElement Function(UiDomNode node) draw;

  /// The ids of the components above this one, root first.
  final List<String> ancestors;

  /// The nodes of the children listed in [prop], expanding a template
  /// over its list.
  List<UiDomNode> nodes(String prop) => switch (component.props[prop]) {
    final List<Object?> ids => [
      for (final id in ids) ?node(id is String ? id : null),
    ],
    {'componentId': final String id, 'path': final String path} => [
      if (scope.read(path) case final List<Object?> items)
        for (var i = 0; i < items.length; i++)
          ?node(id, scope: scope.item(path, i)),
    ],
    _ => const [],
  };

  /// The node of the child [id], or `null` when there is none or it would
  /// contain itself.
  UiDomNode? node(String? id, {UiScope? scope}) {
    final child = surface.components[id];
    if (child == null || ancestors.contains(id) || ancestors.length > 32) {
      return null;
    }
    return UiDomNode(
      controller: controller,
      surface: surface,
      component: child,
      scope: scope ?? this.scope,
      draw: draw,
      ancestors: [...ancestors, component.id],
    );
  }
}
