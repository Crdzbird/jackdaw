@TestOn('browser')
library;

import 'package:test/test.dart';

import 'support/show_dom.dart';

void main() {
  test('a write updates the element that reads it, in place', () {
    final shown = showDom(
      [
        c('root', 'Column', {
          'children': ['fixed', 'bound'],
        }),
        c('fixed', 'Text', {'text': 'Fixed'}),
        c('bound', 'Text', {
          'text': {'@path': '/name'},
        }),
      ],
      data: {'name': 'Before'},
    );
    final texts = shown.host.querySelectorAll('p');
    final fixed = texts.item(0)!;
    final bound = texts.item(1)!;
    expect(bound.textContent, 'Before');
    shown.controller.applyAll([write('/name', 'After')]);
    expect(bound.textContent, 'After');
    expect(shown.host.querySelectorAll('p').item(1)!.isSameNode(bound), isTrue);
    expect(shown.host.querySelectorAll('p').item(0)!.isSameNode(fixed), isTrue);
    shown.view.dispose();
  });

  test('changed components draw the surface again', () async {
    final shown = showDom([
      c('root', 'Text', {'text': 'One'}),
    ]);
    shown.controller.applyAll([
      {
        'version': 'v1.0',
        'updateComponents': {
          'surfaceId': 's',
          'components': [
            c('root', 'Text', {'text': 'Two'}),
          ],
        },
      },
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(shown.host.textContent, 'Two');
    shown.view.dispose();
    expect(shown.host.textContent, '');
  });
}
