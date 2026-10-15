import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/show_surface.dart';

void main() {
  testWidgets('a checkbox toggles its binding and shows its check', (
    tester,
  ) async {
    final controller = await showSurface(
      tester,
      [
        c('root', 'CheckBox', {
          'label': 'Agree',
          'value': {'@path': '/ok'},
          'checks': [
            {
              'condition': {'@path': '/ok'},
              'message': 'You must agree.',
            },
          ],
        }),
      ],
      data: {'ok': false},
    );
    expect(find.text('You must agree.'), findsOneWidget);
    await tester.tap(find.text('Agree'));
    await tester.pump();
    expect(dataAt(controller, '/ok'), isTrue);
    expect(find.text('You must agree.'), findsNothing);
  });

  testWidgets('a slider writes numbers in its range', (tester) async {
    final controller = await showSurface(
      tester,
      [
        c('root', 'Column', {
          'children': ['volume', 'stuck'],
        }),
        c('volume', 'Slider', {
          'label': 'Volume',
          'min': 0,
          'max': 10,
          'steps': 10,
          'value': {'@path': '/v'},
        }),
        c('stuck', 'Slider', {'max': 0, 'value': 5}),
      ],
      data: {'v': 2},
    );
    final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
    expect(sliders.first.divisions, 10);
    expect(sliders.last.onChanged, isNull);
    await tester.tap(find.byType(Slider).first);
    await tester.pump();
    expect(dataAt(controller, '/v'), 5);
  });
}
