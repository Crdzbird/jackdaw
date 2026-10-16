import 'dart:js_interop';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_dom/src/builders/ui_dom_events.dart';
import 'package:jackdaw_dom/src/builders/ui_dom_lazy_text.dart';
import 'package:jackdaw_dom/src/ui_dom_node.dart';
import 'package:jackdaw_dom/src/ui_dom_node_values.dart';
import 'package:jackdaw_dom/src/ui_dom_part.dart';
import 'package:web/web.dart' as web;

int _pickers = 0;

/// A ChoicePicker component bound to a list of chosen values: radio
/// buttons for one choice or checkboxes for several, shown as chips when
/// asked, with a filter field when the component is filterable.
UiDomPart uiDomChoicePicker(UiDomNode node) {
  final props = node.component.props;
  final exclusive = props['variant'] != 'multipleSelection';
  final group = 'jd-choice-${_pickers++}';
  final legend = web.HTMLLegendElement();
  final box = web.HTMLFieldSetElement()
    ..className = props['displayStyle'] == 'chips'
        ? 'jd-choices jd-chips'
        : 'jd-choices'
    ..append(legend);
  final filter = web.HTMLInputElement()
    ..type = 'search'
    ..placeholder = 'Filter';
  if (uiTruth(props['filterable'])) box.append(filter);
  final options = [
    if (props['options'] case final List<Object?> list)
      for (final option in list.whereType<Map<String, Object?>>())
        if (option['value'] case final String value)
          (value: value, label: option['label']),
  ];
  final rows = <(web.HTMLLabelElement, web.HTMLInputElement, web.Text)>[];
  Set<String> chosen() => switch (node.value('value')) {
    final List<Object?> values => {for (final v in values) uiText(v)},
    final String value => {value},
    _ => const {},
  };
  for (final option in options) {
    final input = web.HTMLInputElement()
      ..type = exclusive ? 'radio' : 'checkbox'
      ..name = group
      ..value = option.value;
    final text = web.Text();
    final row = web.HTMLLabelElement()
      ..className = 'jd-choice'
      ..append(input)
      ..append(text);
    uiDomOn(input, 'change', () {
      final on = input.checked;
      final now = chosen();
      node.write('value', switch ((exclusive, on)) {
        (true, true) => [option.value],
        (true, false) => <String>[],
        (false, true) => [...now, option.value],
        (false, false) => [...now.where((v) => v != option.value)],
      });
    });
    rows.add((row, input, text));
    box.append(row);
  }
  void show() {
    final wanted = filter.value.toLowerCase();
    for (final (row, _, text) in rows) {
      row.hidden = (!text.data.toLowerCase().contains(wanted)).toJS;
    }
  }

  uiDomOn(filter, 'input', show);
  void update() {
    legend.textContent = node.text('label');
    final now = chosen();
    for (var i = 0; i < options.length; i++) {
      final (_, input, text) = rows[i];
      input.checked = now.contains(options[i].value);
      text.data = uiText(node.read(options[i].label));
    }
    final messages = node.checkMessages;
    uiDomLazyText(
      box,
      messages.isEmpty ? '' : messages.first,
      () => web.HTMLElement.small()..className = 'jd-error',
    );
    show();
  }

  update();
  return (element: box, update: update);
}
