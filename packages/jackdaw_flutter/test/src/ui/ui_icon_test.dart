import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_svg_icon_painter.dart';

import 'support/show_surface.dart';

void main() {
  testWidgets('icons by name, by binding and from SVG paths', (tester) async {
    await showSurface(
      tester,
      [
        c('root', 'Row', {
          'children': ['a', 'b', 'c', 'd', 'e'],
        }),
        c('a', 'Icon', {'name': 'home'}),
        c('b', 'Icon', {
          'name': {'@path': '/icon'},
        }),
        c('c', 'Icon', {
          'name': {'@path': '/missing'},
        }),
        c('d', 'Icon', {
          'name': {'svgPath': 'M0 0 L24 24 L0 24 Z'},
        }),
        c('e', 'Icon', {
          'name': {'svgPath': 'oops'},
        }),
      ],
      data: {'icon': 'star'},
    );
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.help_outline), findsNWidgets(2));
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .whereType<UiSvgIconPainter>()
        .single;
    expect(painter.shouldRepaint(painter), isFalse);
    expect(
      painter.shouldRepaint(UiSvgIconPainter(Path(), painter.color)),
      isTrue,
    );
  });
}
