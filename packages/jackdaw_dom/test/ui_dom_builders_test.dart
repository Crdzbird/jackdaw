@TestOn('browser')
library;

import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

import 'support/show_dom.dart';

void main() {
  test('a button runs its action, unless a check fails', () {
    final actions = <UiAction>[];
    final shown = showDom(
      [
        c('root', 'Row', {
          'children': ['go', 'card'],
          'justify': 'end',
        }),
        c('go', 'Button', {
          'child': 'label',
          'variant': 'primary',
          'action': {
            'event': {'name': 'go'},
          },
          'checks': [
            {
              'condition': {'@path': '/ready'},
              'message': 'Not ready',
            },
          ],
        }),
        c('label', 'Text', {'text': 'Go', 'variant': 'caption'}),
        c('card', 'Card', {'child': 'line'}),
        c('line', 'Divider', {'axis': 'vertical'}),
      ],
      data: {'ready': true},
      onAction: actions.add,
    );
    final button = shown.host.querySelector('button')! as web.HTMLButtonElement;
    expect(button.getAttribute('data-variant'), 'primary');
    expect(shown.host.querySelector('.jd-caption')!.textContent, 'Go');
    expect(shown.host.querySelector('.jd-vertical'), isNotNull);
    button.click();
    expect(actions.single.name, 'go');
    shown.controller.applyAll([write('/ready', false)]);
    expect(button.disabled, isTrue);
    shown.view.dispose();
  });

  test('a controller ignores surfaces it does not have', () {
    final shown = showDom([
      c('root', 'Text', {'text': 'x'}),
    ]);
    shown.controller
      ..write('none', '/a', 1)
      ..trigger(
        'none',
        UiComponent.fromJson(c('b', 'Button')),
        UiScope(UiDataModel()),
      );
    expect(shown.host.textContent, 'x');
    final stop = shown.controller.watch('s', {'/a'}, () {});
    stop();
    shown.view.dispose();
  });
}
