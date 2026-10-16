@TestOn('browser')
library;

import 'package:jackdaw_dom/jackdaw_dom.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

import 'support/show_dom.dart';

void main() {
  test('a value that fails to evaluate draws as empty text', () {
    final shown = showDom([
      c('root', 'Text', {
        'text': {
          '@call': 'formatDate',
          'args': {'value': 'soon', 'format': 'y'},
        },
      }),
    ]);
    expect(shown.host.querySelector('p')!.textContent, '');
    shown.view.dispose();
  });

  test('a prop that lists no children gives no nodes', () {
    final shown = showDom([
      c('root', 'Text', {'text': 'x'}),
    ]);
    final host = web.HTMLDivElement();
    final view = UiDomView(
      controller: shown.controller,
      surfaceId: 's',
      host: host,
      builders: {
        'Text': (node) => (
          element: web.HTMLSpanElement()
            ..textContent = '${node.nodes('children').length}',
          update: null,
        ),
      },
    );
    expect(host.textContent, '0');
    view.dispose();
    shown.view.dispose();
  });
}
