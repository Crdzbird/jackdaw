@TestOn('browser')
library;

import 'package:jackdaw_dom/src/builders/ui_dom_icon_paths.g.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

import 'support/show_dom.dart';

void main() {
  test('icons draw by name, from a path, or as help', () {
    final shown = showDom(
      [
        c('root', 'Row', {
          'children': ['named', 'drawn', 'bound'],
        }),
        c('named', 'Icon', {'name': 'add'}),
        c('drawn', 'Icon', {
          'name': {'svgPath': 'M0 0L24 24'},
        }),
        c('bound', 'Icon', {
          'name': {'@path': '/icon'},
        }),
      ],
      data: {'icon': 'nothing'},
    );
    String drawn(int i) =>
        (shown.host.querySelectorAll('path').item(i)! as web.Element)
            .getAttribute('d')!;
    expect(drawn(0), uiDomIconPaths['add']);
    expect(drawn(1), 'M0 0L24 24');
    expect(drawn(2), uiDomIconPaths['help']);
    shown.controller.applyAll([write('/icon', 'home')]);
    expect(drawn(2), uiDomIconPaths['home']);
    final box = shown.host.querySelector('.jd-icon')!;
    expect(box.getAttribute('aria-label'), 'add');
    shown.view.dispose();
  });
}
