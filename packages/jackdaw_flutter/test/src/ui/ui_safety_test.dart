import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';

import 'support/show_surface.dart';

const Map<String, Object?> failing = {
  '@call': 'formatDate',
  'args': {'value': 'soon', 'format': 'y'},
};

void main() {
  testWidgets('values that fail to evaluate draw as empty', (tester) async {
    await showSurface(tester, [
      c('root', 'Column', {
        'children': ['t', 'tabs'],
      }),
      c('t', 'Text', {'text': failing}),
      c('tabs', 'Tabs', {
        'tabs': [
          {'title': failing, 'child': 't'},
        ],
      }),
    ]);
    expect(find.byType(Tab), findsOneWidget);
    expect(find.byType(Text), findsWidgets);
  });

  testWidgets('a row in an unbounded width keeps its natural size', (
    tester,
  ) async {
    await showSurface(tester, [
      c('root', 'List', {
        'children': ['row'],
        'direction': 'horizontal',
      }),
      c('row', 'Row', {
        'children': ['a', 'b'],
        'align': 'stretch',
      }),
      c('a', 'Text', {'text': 'A', 'weight': 1}),
      c('b', 'Text', {'text': 'B'}),
    ]);
    expect(find.text('A'), findsOneWidget);
    expect(find.byType(Flexible), findsNothing);
  });

  testWidgets('a failing check shows under the choices', (tester) async {
    await showSurface(
      tester,
      [
        c('root', 'ChoicePicker', {
          'options': [
            {'label': 'Red', 'value': 'r'},
          ],
          'value': {'@path': '/chosen'},
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
      data: {'chosen': <Object?>[]},
    );
    expect(find.text('Pick one.'), findsOneWidget);
  });

  testWidgets('a poster that fails to load falls back to an icon', (
    tester,
  ) async {
    await showSurface(tester, [
      c('root', 'Video', {
        'url': 'https://img.example/v.mp4',
        'posterUrl': 'https://img.example/p.png',
      }),
    ], host: UiHost(allowUrl: (url) => url.host == 'img.example'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_circle), findsOneWidget);
  });
}
