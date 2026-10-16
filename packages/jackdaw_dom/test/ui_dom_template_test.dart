@TestOn('browser')
library;

import 'package:jackdaw_dom/jackdaw_dom.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

import 'support/show_dom.dart';

void main() {
  test('a template draws its items and follows its list', () async {
    final shown = showDom(
      [
        c('root', 'List', {
          'children': {'componentId': 'item', 'path': '/items'},
        }),
        c('item', 'Text', {
          'text': {'@path': 'name'},
        }),
      ],
      data: {
        'items': [
          {'name': 'a'},
        ],
      },
    );
    expect(shown.host.textContent, 'a');
    shown.controller.applyAll([
      write('/items', [
        {'name': 'a'},
        {'name': 'b'},
      ]),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(shown.host.textContent, 'ab');
    shown.view.dispose();
  });

  test('a missing surface, child or builder draws nothing', () {
    final shown = showDom([
      c('root', 'Card', {'child': 'gone'}),
    ]);
    expect(shown.host.querySelector('.jd-card')!.childElementCount, 0);
    shown.view.dispose();
    final host = web.HTMLDivElement();
    final bare = UiDomView(
      controller: shown.controller,
      surfaceId: 's',
      host: host,
      builders: const {},
    );
    expect(host.querySelector('span'), isNotNull);
    bare.dispose();
    final none = UiDomView(
      controller: shown.controller,
      surfaceId: 'none',
      host: host,
    );
    expect(host.childElementCount, 0);
    none.dispose();
  });
}
