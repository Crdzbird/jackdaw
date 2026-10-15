import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/show_surface.dart';

Map<String, Object?> choices(Map<String, Object?> props) =>
    c('root', 'ChoicePicker', {
      'label': 'Pick',
      'options': [
        {'label': 'Red', 'value': 'r'},
        {
          'label': {'@path': '/blue'},
          'value': 'b',
        },
      ],
      'value': {'@path': '/chosen'},
      ...props,
    });

void main() {
  testWidgets('chips pick several values and filter', (tester) async {
    final controller = await showSurface(
      tester,
      [
        choices({
          'variant': 'multipleSelection',
          'displayStyle': 'chips',
          'filterable': true,
        }),
      ],
      data: {'blue': 'Blue', 'chosen': <Object?>[]},
    );
    await tester.tap(find.text('Red'));
    await tester.pump();
    await tester.tap(find.text('Blue'));
    await tester.pump();
    expect(dataAt(controller, '/chosen'), ['r', 'b']);
    await tester.tap(find.text('Red'));
    await tester.pump();
    expect(dataAt(controller, '/chosen'), ['b']);
    await tester.enterText(find.byType(TextField), 'bl');
    await tester.pump();
    expect(find.text('Red'), findsNothing);
    expect(find.byType(FilterChip), findsOneWidget);
  });

  testWidgets('checkboxes pick several and radios pick one', (tester) async {
    final several = await showSurface(
      tester,
      [
        choices({'variant': 'multipleSelection'}),
      ],
      data: {
        'blue': 'Blue',
        'chosen': ['r'],
      },
    );
    await tester.tap(find.text('Blue'));
    await tester.pump();
    expect(dataAt(several, '/chosen'), ['r', 'b']);
    final one = await showSurface(
      tester,
      [
        choices({
          'checks': [
            {
              'condition': {
                '@call': 'required',
                'args': {
                  'value': {'@path': '/chosen'},
                },
              },
              'message': 'Pick one.',
            },
          ],
        }),
      ],
      data: {'blue': 'Blue', 'chosen': 'r'},
    );
    expect(find.text('Pick one.'), findsNothing);
    await tester.tap(find.text('Blue'));
    await tester.pump();
    expect(dataAt(one, '/chosen'), ['b']);
    await showSurface(
      tester,
      [
        choices({'displayStyle': 'chips'}),
      ],
      data: {'chosen': 3},
    );
    await tester.tap(find.text('Red'));
    await tester.pump();
    await tester.tap(find.text('Red'));
    await tester.pump();
    expect(find.text('Pick'), findsOneWidget);
  });
}
