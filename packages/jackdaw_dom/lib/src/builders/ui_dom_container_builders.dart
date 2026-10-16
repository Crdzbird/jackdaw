import 'dart:js_interop';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_dom/src/builders/ui_dom_events.dart';
import 'package:jackdaw_dom/src/ui_dom_node.dart';
import 'package:jackdaw_dom/src/ui_dom_node_values.dart';
import 'package:jackdaw_dom/src/ui_dom_part.dart';
import 'package:web/web.dart' as web;

/// A Tabs component: titled tabs that show one child at a time. Each
/// child is drawn once and hidden while its tab is not chosen, so what is
/// typed in a tab stays when another is shown.
UiDomPart uiDomTabs(UiDomNode node) {
  final tabs = [
    if (node.component.props['tabs'] case final List<Object?> list)
      for (final tab in list.whereType<Map<String, Object?>>()) tab,
  ];
  final bar = web.HTMLDivElement()
    ..className = 'jd-tab-bar'
    ..setAttribute('role', 'tablist');
  final box = web.HTMLDivElement()
    ..className = 'jd-tabs'
    ..append(bar);
  final buttons = <web.HTMLButtonElement>[];
  final panels = <web.HTMLDivElement>[];
  void choose(int chosen) {
    for (var i = 0; i < tabs.length; i++) {
      buttons[i].setAttribute('aria-selected', '${i == chosen}');
      panels[i].hidden = (i != chosen).toJS;
    }
  }

  for (final tab in tabs) {
    final index = buttons.length;
    final button = web.HTMLButtonElement()
      ..type = 'button'
      ..className = 'jd-tab'
      ..setAttribute('role', 'tab');
    uiDomOn(button, 'click', () => choose(index));
    final panel = web.HTMLDivElement()..setAttribute('role', 'tabpanel');
    final child = tab['child'];
    if (node.node(child is String ? child : null) case final inner?) {
      panel.append(node.draw(inner));
    }
    buttons.add(button);
    panels.add(panel);
    bar.append(button);
    box.append(panel);
  }
  void update() {
    for (var i = 0; i < tabs.length; i++) {
      buttons[i].textContent = uiText(node.read(tabs[i]['title']));
    }
  }

  update();
  choose(0);
  return (element: box, update: update);
}

/// A Modal component: its trigger opens a dialog with its content, which
/// closes with Escape or a press outside it.
UiDomPart uiDomModal(UiDomNode node) {
  final dialog = web.HTMLDialogElement()..className = 'jd-dialog';
  final trigger = web.HTMLDivElement()..className = 'jd-modal-trigger';
  for (final (prop, into) in [('trigger', trigger), ('content', dialog)]) {
    final id = node.component.props[prop];
    if (node.node(id is String ? id : null) case final inner?) {
      into.append(node.draw(inner));
    }
  }
  void open() => dialog.showModal();
  uiDomOn(trigger, 'click', open);
  dialog.addEventListener(
    'click',
    ((web.MouseEvent event) {
      if (event.target.isA<web.HTMLDialogElement>()) dialog.close();
    }).toJS,
  );
  final box = web.HTMLDivElement()
    ..className = 'jd-modal'
    ..append(trigger)
    ..append(dialog);
  return (element: box, update: null);
}
