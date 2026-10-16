import 'package:web/web.dart' as web;

/// Keeps [text] in a child of [parent] made by [make], created only once
/// there is text to show and emptied when there is none, so components
/// without a label or a message carry no empty element.
void uiDomLazyText(
  web.HTMLElement parent,
  String text,
  web.HTMLElement Function() make, {
  bool first = false,
}) {
  final existing = parent.querySelector('[data-jd-lazy]');
  if (existing == null && text.isEmpty) return;
  final element = (existing ?? (make()..setAttribute('data-jd-lazy', '')))
    ..textContent = text;
  if (existing != null) return;
  if (first) {
    parent.prepend(element);
    return;
  }
  parent.append(element);
}
