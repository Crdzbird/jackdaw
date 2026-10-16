import 'package:jackdaw_dom/src/builders/ui_dom_events.dart';
import 'package:jackdaw_dom/src/ui_dom_node.dart';
import 'package:jackdaw_dom/src/ui_dom_node_values.dart';
import 'package:jackdaw_dom/src/ui_dom_part.dart';
import 'package:web/web.dart' as web;

/// A DateTimeInput component: the browser's date, time or date and time
/// input, between `min` and `max` when given, writing an ISO 8601 value
/// as jackdaw_flutter does: `2026-10-16`, `09:30` or
/// `2026-10-16T09:30:00`.
UiDomPart uiDomDateTime(UiDomNode node) {
  final input = web.HTMLInputElement();
  final caption = web.HTMLSpanElement();
  final label = web.HTMLLabelElement()
    ..className = 'jd-field'
    ..append(caption)
    ..append(input);
  final time = node.truth('enableTime');
  final date = node.truth('enableDate') || !time;
  input.type = switch ((date, time)) {
    (true, true) => 'datetime-local',
    (false, true) => 'time',
    _ => 'date',
  };
  final width = switch ((date, time)) {
    (true, true) => 16,
    (false, true) => 5,
    _ => 10,
  };
  String shown(String value) =>
      value.length > width ? value.substring(0, width) : value;
  uiDomOn(input, 'change', () {
    final value = input.value;
    node.write(
      'value',
      date && time && value.length == 16 ? '$value:00' : value,
    );
  });
  void update() {
    caption.textContent = node.text('label');
    input
      ..value = shown(node.text('value'))
      ..min = shown(node.text('min'))
      ..max = shown(node.text('max'));
  }

  update();
  return (element: label, update: update);
}
