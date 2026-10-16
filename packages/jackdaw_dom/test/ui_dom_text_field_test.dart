@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:web/web.dart' as web;

import 'support/show_dom.dart';

const Map<String, Object?> _required = {
  'condition': {
    '@call': 'required',
    'args': {
      'value': {'@path': '/name'},
    },
  },
  'message': 'Needed',
};

void main() {
  test('a text field writes what is typed and shows its check', () {
    final shown = showDom(
      [
        c('root', 'TextField', {
          'label': 'Name',
          'placeholder': 'Your name',
          'value': {'@path': '/name'},
          'checks': [_required],
        }),
      ],
      data: {'name': 'Ada'},
    );
    final input = shown.host.querySelector('input')! as web.HTMLInputElement;
    expect(input.value, 'Ada');
    expect(input.getAttribute('placeholder'), 'Your name');
    input
      ..value = ''
      ..dispatchEvent(web.Event('input'));
    expect(shown.controller.surfaces.surfaces['s']!.data.read('/name'), '');
    expect(shown.host.querySelector('.jd-error')!.textContent, 'Needed');
    shown.controller.applyAll([write('/name', 'Grace')]);
    expect(input.value, 'Grace');
    shown.view.dispose();
  });

  test('a long text field is a text area, and others pick a type', () {
    final shown = showDom([
      c('root', 'Column', {
        'children': ['long', 'number', 'secret'],
      }),
      c('long', 'TextField', {
        'label': 'Long',
        'variant': 'longText',
        'value': {'@path': '/long'},
      }),
      c('number', 'TextField', {
        'label': 'Number',
        'variant': 'number',
        'value': {'@path': '/number'},
      }),
      c('secret', 'TextField', {
        'label': 'Secret',
        'variant': 'obscured',
        'value': {'@path': '/secret'},
      }),
    ]);
    final area =
        shown.host.querySelector('textarea')! as web.HTMLTextAreaElement;
    final types = [
      for (var i = 0; i < 2; i++)
        (shown.host.querySelectorAll('input').item(i)! as web.HTMLInputElement)
            .type,
    ];
    expect(types, ['number', 'password']);
    area
      ..value = 'many lines'
      ..dispatchEvent(web.Event('input'));
    shown.controller.applyAll([write('/long', 'replaced')]);
    expect(area.value, 'replaced');
    shown.view.dispose();
  });
}
