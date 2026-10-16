@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:web/web.dart' as web;

import 'support/show_dom.dart';

void main() {
  test('a checkbox and a slider write their values', () {
    final shown = showDom([
      c('root', 'Column', {
        'children': ['box', 'level', 'flat'],
      }),
      c('box', 'CheckBox', {
        'label': 'Agree',
        'value': {'@path': '/ok'},
      }),
      c('level', 'Slider', {
        'label': 'Level',
        'max': 10,
        'steps': 5,
        'value': {'@path': '/level'},
      }),
      c('flat', 'Slider', {
        'min': 3,
        'max': 3,
        'value': {'@path': '/flat'},
      }),
    ]);
    final inputs = shown.host.querySelectorAll('input');
    final box = inputs.item(0)! as web.HTMLInputElement;
    final level = inputs.item(1)! as web.HTMLInputElement;
    final flat = inputs.item(2)! as web.HTMLInputElement;
    box
      ..checked = true
      ..dispatchEvent(web.Event('change'));
    level
      ..value = '4'
      ..dispatchEvent(web.Event('input'));
    final data = shown.controller.surfaces.surfaces['s']!.data;
    expect(data.read('/ok'), true);
    expect(data.read('/level'), 4);
    expect(level.step, '2');
    expect(flat.disabled, isTrue);
    shown.view.dispose();
  });
}
