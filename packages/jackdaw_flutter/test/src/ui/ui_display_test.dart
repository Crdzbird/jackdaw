import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_rule.dart';

import 'support/show_surface.dart';

void main() {
  testWidgets('text, cards and dividers', (tester) async {
    await showSurface(tester, [
      c('root', 'Column', {
        'children': ['t', 'card', 'line', 'bar'],
      }),
      c('t', 'Text', {'text': 'Body', 'variant': 'body'}),
      c('card', 'Card', {'child': 'cap'}),
      c('cap', 'Text', {'text': 'Small', 'variant': 'caption'}),
      c('line', 'Divider'),
      c('bar', 'Divider', {'axis': 'vertical'}),
    ]);
    expect(find.text('Body'), findsOneWidget);
    expect(find.text('Small'), findsOneWidget);
    expect(find.byType(UiRule), findsOneWidget);
    expect(find.byType(VerticalDivider), findsOneWidget);
  });

  testWidgets('accessibility labels, live regions and hidden parts', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await showSurface(tester, [
      c('root', 'Column', {
        'children': ['a', 'b', 'c'],
      }),
      c('a', 'Text', {
        'text': 'Total',
        'accessibility': {'label': 'Order total', 'live': 'polite'},
      }),
      c('b', 'Text', {
        'text': 'Secret',
        'accessibility': {'hidden': true},
      }),
      c('c', 'Text', {
        'text': 'Plain',
        'accessibility': {
          'label': {
            '@call': 'formatDate',
            'args': {'value': 'soon', 'format': 'y'},
          },
        },
      }),
    ]);
    expect(find.bySemanticsLabel(RegExp('Order total')), findsOneWidget);
    expect(find.bySemanticsLabel('Secret'), findsNothing);
    expect(find.bySemanticsLabel('Plain'), findsOneWidget);
    handle.dispose();
  });
}
