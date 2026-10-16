@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:test/test.dart';
import 'package:web/web.dart' as web;

import 'support/show_dom.dart';

void main() {
  test('tabs show one child at a time and follow their titles', () {
    final shown = showDom(
      [
        c('root', 'Tabs', {
          'tabs': [
            {
              'title': {'@path': '/first'},
              'child': 'one',
            },
            {'title': 'Second', 'child': 'two'},
          ],
        }),
        c('one', 'Text', {'text': 'One'}),
        c('two', 'Text', {'text': 'Two'}),
      ],
      data: {'first': 'First'},
    );
    final tabs = shown.host.querySelectorAll('[role=tab]');
    final panels = shown.host.querySelectorAll('[role=tabpanel]');
    web.HTMLElement panel(int i) => panels.item(i)! as web.HTMLElement;
    expect(tabs.item(0)!.textContent, 'First');
    expect(panel(1).hidden.dartify(), isTrue);
    (tabs.item(1)! as web.HTMLElement).click();
    expect(panel(0).hidden.dartify(), isTrue);
    expect(panel(1).hidden.dartify(), isFalse);
    shown.controller.applyAll([write('/first', 'Renamed')]);
    expect(tabs.item(0)!.textContent, 'Renamed');
    shown.view.dispose();
  });

  test('a modal opens its content from its trigger and closes outside', () {
    final shown = showDom([
      c('root', 'Modal', {'trigger': 'open', 'content': 'body'}),
      c('open', 'Text', {'text': 'Open'}),
      c('body', 'Text', {'text': 'Inside'}),
    ]);
    final dialog = shown.host.querySelector('dialog')! as web.HTMLDialogElement;
    expect(dialog.textContent, 'Inside');
    (shown.host.querySelector('.jd-modal-trigger')! as web.HTMLElement).click();
    expect(dialog.open, isTrue);
    (shown.host.querySelector('dialog p')! as web.HTMLElement).click();
    expect(dialog.open, isTrue);
    dialog.click();
    expect(dialog.open, isFalse);
    shown.view.dispose();
  });
}
