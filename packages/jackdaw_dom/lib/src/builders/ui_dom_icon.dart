import 'package:jackdaw_dom/src/builders/ui_dom_icon_paths.g.dart';
import 'package:jackdaw_dom/src/ui_dom_node.dart';
import 'package:jackdaw_dom/src/ui_dom_node_values.dart';
import 'package:jackdaw_dom/src/ui_dom_part.dart';
import 'package:web/web.dart' as web;

const String _svg = 'http://www.w3.org/2000/svg';

/// An Icon component: a Material icon by name, or one drawn from an SVG
/// path in a 24 by 24 box; an unknown name draws the help icon.
UiDomPart uiDomIcon(UiDomNode node) {
  final path = web.document.createElementNS(_svg, 'path');
  final svg = web.document.createElementNS(_svg, 'svg')
    ..setAttribute('viewBox', '0 0 24 24')
    ..setAttribute('aria-hidden', 'true')
    ..append(path);
  final box = web.HTMLSpanElement()
    ..className = 'jd-icon'
    ..setAttribute('role', 'img')
    ..append(svg);
  void update() {
    final name = node.value('name');
    final data = switch (name) {
      {'svgPath': final String drawn} => drawn,
      final String known when uiDomIconPaths.containsKey(known) =>
        uiDomIconPaths[known]!,
      _ => uiDomIconPaths['help']!,
    };
    path.setAttribute('d', data);
    box.setAttribute('aria-label', name is String ? name : '');
  }

  update();
  return (element: box, update: update);
}
