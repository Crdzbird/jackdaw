import 'package:jackdaw_dom/src/ui_dom_node.dart';
import 'package:jackdaw_dom/src/ui_dom_node_values.dart';
import 'package:jackdaw_dom/src/ui_dom_part.dart';
import 'package:web/web.dart' as web;

/// A Text component: body text, or a caption.
UiDomPart uiDomText(UiDomNode node) {
  final text = web.HTMLParagraphElement()
    ..className = node.component.props['variant'] == 'caption'
        ? 'jd-text jd-caption'
        : 'jd-text';
  void update() => text.textContent = node.text('text');
  update();
  return (element: text, update: update);
}

/// A Divider component, across or along its parent.
UiDomPart uiDomDivider(UiDomNode node) => (
  element: web.HTMLHRElement()
    ..className = node.component.props['axis'] == 'vertical'
        ? 'jd-divider jd-vertical'
        : 'jd-divider',
  update: null,
);
