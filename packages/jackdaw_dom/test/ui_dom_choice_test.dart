@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:test/test.dart';
import 'package:web/web.dart' as web;

import 'support/show_dom.dart';

Map<String, Object?> _picker(
  String id,
  String path, [
  Map<String, Object?> p = const {},
]) => c(id, 'ChoicePicker', {
  'label': 'Pick',
  'options': [
    {'label': 'Red', 'value': 'red'},
    {
      'label': {'@path': '/blue'},
      'value': 'blue',
    },
  ],
  'value': {'@path': path},
  ...p,
});

void main() {
  test('one choice writes a list of one, and several add and remove', () {
    final shown = showDom(
      [
        c('root', 'Column', {
          'children': ['one', 'many'],
        }),
        _picker('one', '/one'),
        _picker('many', '/many', {
          'variant': 'multipleSelection',
          'displayStyle': 'chips',
          'checks': [
            {
              'condition': {
                '@call': 'required',
                'args': {
                  'value': {'@path': '/many'},
                },
              },
              'message': 'Pick one',
            },
          ],
        }),
      ],
      data: {'blue': 'Blue', 'one': 'red'},
    );
    final inputs = shown.host.querySelectorAll('input');
    web.HTMLInputElement input(int i) =>
        inputs.item(i)! as web.HTMLInputElement;
    expect(input(0).checked, isTrue);
    expect(input(0).type, 'radio');
    expect(shown.host.textContent, contains('Blue'));
    final data = shown.controller.surfaces.surfaces['s']!.data;
    void set(int i, {required bool on}) => input(i)
      ..checked = on
      ..dispatchEvent(web.Event('change'));
    set(1, on: true);
    expect(data.read('/one'), ['blue']);
    set(1, on: false);
    expect(data.read('/one'), <String>[]);
    expect(
      shown.host.querySelector('.jd-chips .jd-error')!.textContent,
      'Pick one',
    );
    set(2, on: true);
    set(3, on: true);
    expect(data.read('/many'), ['red', 'blue']);
    set(2, on: false);
    expect(data.read('/many'), ['blue']);
    shown.view.dispose();
  });

  test('a filterable picker hides the options its filter leaves out', () {
    final shown = showDom(
      [
        _picker('root', '/v', {'filterable': true}),
      ],
      data: {'blue': 'Blue'},
    );
    (shown.host.querySelector('input[type=search]')! as web.HTMLInputElement)
      ..value = 'bl'
      ..dispatchEvent(web.Event('input'));
    final rows = shown.host.querySelectorAll('.jd-choice');
    expect((rows.item(0)! as web.HTMLElement).hidden.dartify(), isTrue);
    expect((rows.item(1)! as web.HTMLElement).hidden.dartify(), isFalse);
    shown.view.dispose();
  });
}
