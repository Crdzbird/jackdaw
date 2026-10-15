import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';

import 'support/show_surface.dart';

Map<String, Object?> button(String id, String variant) => c(id, 'Button', {
  'child': '$id-label',
  'variant': variant,
  'action': {
    'event': {'name': id},
  },
});

void main() {
  testWidgets('button variants send their events', (tester) async {
    final actions = <UiAction>[];
    await showSurface(tester, [
      c('root', 'Row', {
        'children': ['p', 'b', 'd'],
      }),
      button('p', 'primary'),
      c('p-label', 'Text', {'text': 'Primary'}),
      button('b', 'borderless'),
      c('b-label', 'Text', {'text': 'Borderless'}),
      button('d', 'default'),
      c('d-label', 'Text', {'text': 'Default'}),
    ], onAction: actions.add);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    for (final label in ['Primary', 'Borderless', 'Default']) {
      await tester.tap(find.text(label));
    }
    expect(actions.map((a) => a.name), ['p', 'b', 'd']);
  });

  testWidgets('text field variants and literal values', (tester) async {
    final controller = await showSurface(tester, [
      c('root', 'Column', {
        'children': ['secret', 'count', 'notes', 'fixed'],
      }),
      c('secret', 'TextField', {
        'label': 'Password',
        'variant': 'obscured',
        'value': {'@path': '/pw'},
        'placeholder': 'Hidden',
      }),
      c('count', 'TextField', {'label': 'Count', 'variant': 'number'}),
      c('notes', 'TextField', {'label': 'Notes', 'variant': 'longText'}),
      c('fixed', 'TextField', {
        'label': 'Fixed',
        'value': 'start',
        'checks': [
          {
            'condition': {
              '@call': 'length',
              'args': {'value': 'start', 'max': 2},
            },
            'message': 'Too long.',
          },
        ],
      }),
    ]);
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].obscureText, isTrue);
    expect(fields[1].keyboardType, TextInputType.number);
    expect(fields[2].maxLines, isNull);
    controller.write('s', '/pw', 'from data');
    await tester.pump();
    expect(find.text('from data'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'start'), 'typed');
    await tester.pump();
    expect(find.text('typed'), findsOneWidget);
    expect(find.text('Too long.'), findsOneWidget);
  });
}
