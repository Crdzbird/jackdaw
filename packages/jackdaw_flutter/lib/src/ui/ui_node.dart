import 'package:flutter/widgets.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/ui/ui_bound.dart';
import 'package:jackdaw_flutter/src/ui/ui_surface_controller.dart';
import 'package:jackdaw_flutter/src/ui/ui_widget_builder.dart';

/// One component being drawn: its props evaluated in its scope, its
/// children, and the ways it writes data and triggers actions.
final class UiNode {
  /// Creates the node of [component] on [surface] in [scope].
  const factory({
    required UiSurfaceController controller,
    required UiSurface surface,
    required UiComponent component,
    required UiScope scope,
    required Map<String, UiWidgetBuilder> builders,
    List<String> ancestors,
  }) = UiNode._;

  const new _({
    required this.controller,
    required this.surface,
    required this.component,
    required this.scope,
    required this.builders,
    this.ancestors = const [],
  });

  /// The controller the surface belongs to.
  final UiSurfaceController controller;

  /// The surface being drawn.
  final UiSurface surface;

  /// The component this node draws.
  final UiComponent component;

  /// Where its bindings are read: the root, or a list item of a template.
  final UiScope scope;

  /// The builders of the components, by name.
  final Map<String, UiWidgetBuilder> builders;

  /// The ids of the components above this one, root first.
  final List<String> ancestors;

  /// Runs this component's action, after a press.
  void trigger() => controller.trigger(surface.id, component, scope);

  /// The node of the child [id], in [scope] or this node's scope, or
  /// `null` when there is none or it would contain itself.
  UiNode? node(String? id, {UiScope? scope}) {
    final child = surface.components[id];
    if (child == null || ancestors.contains(id) || ancestors.length > 32) {
      return null;
    }
    return UiNode(
      controller: controller,
      surface: surface,
      component: child,
      scope: scope ?? this.scope,
      builders: builders,
      ancestors: [...ancestors, component.id],
    );
  }

  /// The nodes of the children listed in [prop], expanding a template
  /// over its list.
  List<UiNode> nodes(String prop) => switch (component.props[prop]) {
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

  /// The widget of the child named by [prop].
  Widget child(String prop) =>
      node(
        component.props[prop] is String
            ? component.props[prop]! as String
            : null,
      )?.build() ??
      const SizedBox.shrink();

  /// The widget of this node, with its accessibility attributes. It
  /// redraws by itself when data it reads is written.
  Widget build() =>
      UiBound(key: ValueKey('${scope.path}#${component.id}'), node: this);
}
