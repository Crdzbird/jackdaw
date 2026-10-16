@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:web/web.dart' as web;

import 'support/show_dom.dart';

void main() {
  test('dates, times and both pick the input and the value they write', () {
    final shown = showDom(
      [
        c('root', 'Column', {
          'children': ['day', 'clock', 'both'],
        }),
        c('day', 'DateTimeInput', {
          'label': 'Day',
          'value': {'@path': '/day'},
          'min': '2026-01-01',
          'max': '2026-12-31',
        }),
        c('clock', 'DateTimeInput', {
          'enableTime': true,
          'value': {'@path': '/clock'},
        }),
        c('both', 'DateTimeInput', {
          'enableDate': true,
          'enableTime': true,
          'value': {'@path': '/both'},
        }),
      ],
      data: {'day': '2026-10-16', 'both': '2026-10-16T09:30:00'},
    );
    final inputs = shown.host.querySelectorAll('input');
    web.HTMLInputElement input(int i) =>
        inputs.item(i)! as web.HTMLInputElement;
    expect(
      [for (var i = 0; i < 3; i++) input(i).type],
      ['date', 'time', 'datetime-local'],
    );
    expect(input(0).value, '2026-10-16');
    expect(input(0).min, '2026-01-01');
    expect(input(2).value, '2026-10-16T09:30');
    final data = shown.controller.surfaces.surfaces['s']!.data;
    void set(int i, String value) => input(i)
      ..value = value
      ..dispatchEvent(web.Event('change'));
    set(1, '08:15');
    set(2, '2026-11-01T10:00');
    expect(data.read('/clock'), '08:15');
    expect(data.read('/both'), '2026-11-01T10:00:00');
    shown.view.dispose();
  });
}
