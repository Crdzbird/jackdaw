import 'package:jackdaw_dom/src/ui_dom_node.dart';
import 'package:jackdaw_dom/src/ui_dom_part.dart';
import 'package:web/web.dart' as web;

/// A Column component: children one above the other, stretched across
/// unless its `align` says otherwise.
UiDomPart uiDomColumn(UiDomNode node) => _flex(node, 'jd-column');

/// A Row component: children side by side.
UiDomPart uiDomRow(UiDomNode node) => _flex(node, 'jd-row');

/// A List component: a column, or a row that scrolls sideways.
UiDomPart uiDomList(UiDomNode node) => _flex(
  node,
  node.component.props['direction'] == 'horizontal'
      ? 'jd-row jd-scroll'
      : 'jd-column',
);

/// A Card component: an outlined box around its child.
UiDomPart uiDomCard(UiDomNode node) {
  final card = web.HTMLDivElement()..className = 'jd-card';
  final child = node.component.props['child'];
  if (node.node(child is String ? child : null) case final inner?) {
    card.append(node.draw(inner));
  }
  return (element: card, update: null);
}

UiDomPart _flex(UiDomNode node, String className) {
  final box = web.HTMLDivElement()..className = className;
  for (final key in ['justify', 'align']) {
    if (node.component.props[key] case final String value) {
      box.setAttribute('data-$key', value);
    }
  }
  for (final child in node.nodes('children')) {
    box.append(node.draw(child));
  }
  return (element: box, update: null);
}
