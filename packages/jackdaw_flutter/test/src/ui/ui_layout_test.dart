import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/show_surface.dart';

void main() {
  testWidgets('rows, columns and lists place their children', (tester) async {
    await showSurface(tester, [
      c('root', 'Column', {
        'children': ['row', 'list', 'side'],
        'justify': 'center',
        'align': 'start',
      }),
      c('row', 'Row', {
        'children': ['a', 'b'],
        'justify': 'spaceBetween',
        'align': 'end',
      }),
      c('a', 'Text', {'text': 'A', 'weight': 2}),
      c('b', 'Text', {'text': 'B'}),
      c('list', 'List', {
        'children': ['c'],
        'align': 'center',
      }),
      c('c', 'Text', {'text': 'C'}),
      c('side', 'List', {
        'children': ['d'],
        'direction': 'horizontal',
      }),
      c('d', 'Text', {'text': 'D'}),
    ]);
    for (final text in ['A', 'B', 'C', 'D']) {
      expect(find.text(text), findsOneWidget);
    }
    final flexible = tester.widget<Flexible>(
      find.ancestor(of: find.text('A'), matching: find.byType(Flexible)).first,
    );
    expect((flexible.flex, flexible.fit), (2, FlexFit.tight));
    expect(find.byType(SingleChildScrollView), findsNWidgets(2));
    for (final justify in ['end', 'spaceAround', 'spaceEvenly', 'stretch']) {
      await showSurface(tester, [
        c('root', 'Row', {
          'children': ['x'],
          'justify': justify,
          'align': justify == 'end' ? 'stretch' : 'center',
        }),
        c('x', 'Text', {'text': justify}),
      ]);
      expect(find.text(justify), findsOneWidget);
    }
  });

  testWidgets('templates repeat over the data model', (tester) async {
    await showSurface(
      tester,
      [
        c('root', 'List', {
          'children': {'componentId': 'item', 'path': '/birds'},
        }),
        c('item', 'Text', {
          'text': {'@path': 'name'},
        }),
      ],
      data: {
        'birds': [
          {'name': 'Jackdaw'},
          {'name': 'Rook'},
        ],
      },
    );
    expect(find.text('Jackdaw'), findsOneWidget);
    expect(find.text('Rook'), findsOneWidget);
    await showSurface(tester, [
      c('root', 'Column', {
        'children': {'componentId': 'item', 'path': '/none'},
      }),
      c('item', 'Text', {'text': 'never'}),
    ]);
    expect(find.text('never'), findsNothing);
  });
}
