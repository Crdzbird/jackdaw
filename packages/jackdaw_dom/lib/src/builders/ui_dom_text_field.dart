import 'package:jackdaw_dom/src/builders/ui_dom_events.dart';
import 'package:jackdaw_dom/src/builders/ui_dom_lazy_text.dart';
import 'package:jackdaw_dom/src/ui_dom_node.dart';
import 'package:jackdaw_dom/src/ui_dom_node_values.dart';
import 'package:jackdaw_dom/src/ui_dom_part.dart';
import 'package:web/web.dart' as web;

/// A TextField component bound to the data model: a line, a number, a
/// password or a long text, with the message of its first failing check
/// once the user has typed.
UiDomPart uiDomTextField(UiDomNode node) {
  final variant = node.component.props['variant'];
  final area = variant == 'longText'
      ? (web.HTMLTextAreaElement()..rows = 3)
      : null;
  final input = area == null
      ? (web.HTMLInputElement()
          ..type = switch (variant) {
            'number' => 'number',
            'obscured' => 'password',
            _ => 'text',
          })
      : null;
  final field = area ?? input!;
  final caption = web.HTMLSpanElement();
  final label = web.HTMLLabelElement()
    ..className = 'jd-field'
    ..append(caption)
    ..append(field);
  var edited = false;
  String current() => area?.value ?? input!.value;
  uiDomOn(field, 'input', () {
    edited = true;
    node.write('value', current());
  });
  void update() {
    final value = node.text('value');
    if (current() != value) {
      area?.value = value;
      input?.value = value;
    }
    caption.textContent = node.text('label');
    final placeholder = node.text('placeholder');
    if (placeholder.isNotEmpty) field.setAttribute('placeholder', placeholder);
    final messages = node.checkMessages;
    uiDomLazyText(
      label,
      edited && messages.isNotEmpty ? messages.first : '',
      () => web.HTMLElement.small()..className = 'jd-error',
    );
  }

  update();
  return (element: label, update: update);
}
