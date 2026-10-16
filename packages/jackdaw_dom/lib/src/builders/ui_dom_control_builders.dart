import 'package:jackdaw_dom/src/builders/ui_dom_events.dart';
import 'package:jackdaw_dom/src/builders/ui_dom_lazy_text.dart';
import 'package:jackdaw_dom/src/ui_dom_node.dart';
import 'package:jackdaw_dom/src/ui_dom_node_values.dart';
import 'package:jackdaw_dom/src/ui_dom_part.dart';
import 'package:web/web.dart' as web;

/// A Button component, disabled while one of its checks fails.
UiDomPart uiDomButton(UiDomNode node) {
  final button = web.HTMLButtonElement()
    ..className = 'jd-button'
    ..type = 'button';
  if (node.component.props['variant'] case final String variant) {
    button.setAttribute('data-variant', variant);
  }
  final child = node.component.props['child'];
  if (node.node(child is String ? child : null) case final inner?) {
    button.append(node.draw(inner));
  }
  uiDomOn(button, 'click', node.trigger);
  void update() => button.disabled = node.checkMessages.isNotEmpty;
  update();
  return (element: button, update: update);
}

/// A CheckBox component bound to the data model, with the message of its
/// first failing check.
UiDomPart uiDomCheckBox(UiDomNode node) {
  final box = web.HTMLInputElement()..type = 'checkbox';
  final label = web.HTMLSpanElement();
  final row = web.HTMLLabelElement()
    ..className = 'jd-check'
    ..append(box)
    ..append(label);
  uiDomOn(box, 'change', () => node.write('value', box.checked));
  void update() {
    box.checked = node.truth('value');
    label.textContent = node.text('label');
    final messages = node.checkMessages;
    uiDomLazyText(
      row,
      messages.isEmpty ? '' : messages.first,
      () => web.HTMLElement.small()..className = 'jd-error',
    );
  }

  update();
  return (element: row, update: update);
}
