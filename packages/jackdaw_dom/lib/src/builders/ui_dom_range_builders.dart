import 'package:jackdaw_dom/src/builders/ui_dom_events.dart';
import 'package:jackdaw_dom/src/builders/ui_dom_lazy_text.dart';
import 'package:jackdaw_dom/src/ui_dom_node.dart';
import 'package:jackdaw_dom/src/ui_dom_node_values.dart';
import 'package:jackdaw_dom/src/ui_dom_part.dart';
import 'package:web/web.dart' as web;

/// A Slider component: a number between `min` and `max`, in `steps`
/// steps when given, bound to the data model.
UiDomPart uiDomSlider(UiDomNode node) {
  final range = web.HTMLInputElement()..type = 'range';
  final label = web.HTMLLabelElement()
    ..className = 'jd-slider'
    ..append(range);
  uiDomOn(range, 'input', () => node.write('value', range.valueAsNumber));
  void update() {
    final min = node.number('min') ?? 0;
    final max = (node.number('max') ?? 1).clamp(min, double.infinity);
    final steps = node.number('steps')?.round();
    range
      ..min = _number(min)
      ..max = _number(max)
      ..step = steps == null || steps < 1 || max == min
          ? 'any'
          : _number((max - min) / steps)
      ..disabled = max == min
      ..value = _number((node.number('value') ?? min).clamp(min, max));
    uiDomLazyText(
      label,
      node.text('label'),
      web.HTMLSpanElement.new,
      first: true,
    );
  }

  update();
  return (element: label, update: update);
}

String _number(double value) =>
    value == value.truncateToDouble() ? '${value.toInt()}' : '$value';
