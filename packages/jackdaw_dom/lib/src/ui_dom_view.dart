import 'dart:async';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_dom/src/builders/basic_dom_builders.dart';
import 'package:jackdaw_dom/src/ui_dom_controller.dart';
import 'package:jackdaw_dom/src/ui_dom_node.dart';
import 'package:jackdaw_dom/src/ui_dom_part.dart';
import 'package:web/web.dart' as web;

/// Draws the surface [surfaceId] of a controller inside [host] as plain
/// HTML elements. Each component is built once; a data write updates in
/// place only the elements whose props read what was written, and the
/// surface is built again only when its components change. A component
/// without one of [builders], a missing child or a cycle draws nothing.
final class UiDomView {
  /// Shows [surfaceId] of [controller] inside [host], until [dispose].
  factory({
    required UiDomController controller,
    required String surfaceId,
    required web.Element host,
    Map<String, UiDomBuilder> builders,
  }) = UiDomView._;

  new _({
    required this.controller,
    required this.surfaceId,
    required this.host,
    this.builders = basicDomBuilders,
  }) {
    _stopListening = controller.listen(surfaceId, _schedule);
    _render();
  }

  /// The controller that holds the surface.
  final UiDomController controller;

  /// The surface to draw.
  final String surfaceId;

  /// The element the surface is drawn in.
  final web.Element host;

  /// The builders of the components, by name.
  final Map<String, UiDomBuilder> builders;

  late final void Function() _stopListening;
  final List<void Function()> _stopWatching = [];
  bool _scheduled = false;

  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    scheduleMicrotask(_render);
  }

  void _render() {
    _scheduled = false;
    _unwatch();
    host.textContent = '';
    final surface = controller.surfaces.surfaces[surfaceId];
    final root = surface?.root;
    if (surface == null || root == null) return;
    final node = UiDomNode(
      controller: controller,
      surface: surface,
      component: root,
      scope: UiScope(surface.data),
      draw: _draw,
    );
    host.append(_draw(node));
  }

  web.HTMLElement _draw(UiDomNode node) {
    final builder = builders[node.component.type];
    if (builder == null) return web.HTMLSpanElement();
    final part = builder(node);
    final paths = uiBoundPaths(node.component.props, node.scope.path);
    if (paths.isNotEmpty) {
      _stopWatching.add(
        controller.watch(surfaceId, paths, part.update ?? _schedule),
      );
    }
    return part.element;
  }

  void _unwatch() {
    for (final stop in _stopWatching) {
      stop();
    }
    _stopWatching.clear();
  }

  /// Stops drawing and empties [host].
  void dispose() {
    _stopListening();
    _unwatch();
    host.textContent = '';
  }
}
