import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw_flutter/src/ui/ui_bound.dart';

import 'support/show_surface.dart';

void main() {
  testWidgets('only components that read data get a layer of their own', (
    tester,
  ) async {
    await showSurface(
      tester,
      [
        c('root', 'Column', {
          'children': ['fixed', 'bound'],
        }),
        c('fixed', 'Text', {'text': 'Fixed'}),
        c('bound', 'Text', {
          'text': {'@path': '/name'},
        }),
      ],
      data: {'name': 'Bound'},
    );
    Finder layers(String text) => find.ancestor(
      of: find.text(text),
      matching: find.descendant(
        of: find.byType(UiBound),
        matching: find.byType(RepaintBoundary),
      ),
    );
    expect(layers('Bound'), findsOneWidget);
    expect(layers('Fixed'), findsNothing);
  });
}
