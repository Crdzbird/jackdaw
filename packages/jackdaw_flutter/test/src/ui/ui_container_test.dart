import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/show_surface.dart';

void main() {
  testWidgets('tabs show one child at a time', (tester) async {
    await showSurface(
      tester,
      [
        c('root', 'Tabs', {
          'tabs': [
            {'title': 'One', 'child': 'a'},
            {
              'title': {'@path': '/second'},
              'child': 'b',
            },
          ],
        }),
        c('a', 'Text', {'text': 'First page'}),
        c('b', 'Text', {'text': 'Second page'}),
      ],
      data: {'second': 'Two'},
    );
    expect(find.text('First page'), findsOneWidget);
    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();
    expect(find.text('Second page'), findsOneWidget);
    expect(find.text('First page'), findsNothing);
  });

  testWidgets('a modal opens from its trigger', (tester) async {
    await showSurface(tester, [
      c('root', 'Modal', {'trigger': 'open', 'content': 'body'}),
      c('open', 'Button', {
        'child': 'label',
        'action': {
          'event': {'name': 'never'},
        },
      }),
      c('label', 'Text', {'text': 'Details'}),
      c('body', 'Text', {'text': 'Inside the dialog'}),
    ]);
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    expect(find.text('Inside the dialog'), findsOneWidget);
  });

  testWidgets('cycles, missing children and unknown parts draw nothing', (
    tester,
  ) async {
    final controller = await showSurface(tester, [
      c('root', 'Card', {'child': 'loop'}),
      c('loop', 'Card', {'child': 'root'}),
    ]);
    expect(find.byType(Card), findsNothing);
    controller.surfaces.surfaces['s']!.components['loop'] =
        controller.surfaces.surfaces['s']!.components['root']!;
    await showSurface(tester, [
      c('root', 'Column', {
        'children': ['gone', 'tabs'],
      }),
      c('tabs', 'Tabs', {'tabs': <Object?>[]}),
    ]);
    expect(find.byType(TabBar), findsNothing);
  });
}
