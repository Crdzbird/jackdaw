import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jackdaw_flutter/src/ui/ui_layer.dart';

import 'support/show_surface.dart';

void main() {
  testWidgets('a column stretches when its width is bounded', (tester) async {
    await showSurface(tester, [
      c('root', 'Column', {
        'children': ['a'],
      }),
      c('a', 'Text', {'text': 'Wide'}),
    ]);
    final text = tester.getSize(find.byType(Padding).first);
    expect(text.width, tester.getSize(find.byType(Scaffold)).width);
  });

  testWidgets('a column in a sideways list starts instead of stretching', (
    tester,
  ) async {
    await showSurface(tester, [
      c('root', 'List', {
        'children': ['col'],
        'direction': 'horizontal',
      }),
      c('col', 'Column', {
        'children': ['a', 'b'],
      }),
      c('a', 'Text', {'text': 'Short'}),
      c('b', 'Text', {'text': 'A longer line'}),
    ]);
    expect(tester.takeException(), isNull);
    expect(find.text('Short'), findsOneWidget);
    final short = tester.getSize(find.text('Short')).width;
    final long = tester.getSize(find.text('A longer line')).width;
    expect(short, lessThan(long));
  });

  testWidgets('its dry layout matches its layout', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: UiLayer(stretch: true, child: SizedBox(height: 10)),
        ),
      ),
    );
    final box = tester.renderObject<RenderBox>(find.byType(UiLayer));
    expect(
      box.getDryLayout(const BoxConstraints(maxWidth: 100)),
      const Size(100, 10),
    );
    expect(box.getDryLayout(const BoxConstraints()), const Size(0, 10));
  });

  testWidgets('it stops stretching when its column says so', (tester) async {
    Widget layer({required bool stretch}) => Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 100,
          child: Align(
            alignment: Alignment.topLeft,
            child: UiLayer(
              stretch: stretch,
              child: const SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(layer(stretch: true));
    expect(tester.getSize(find.byType(UiLayer)).width, 100);
    await tester.pumpWidget(layer(stretch: false));
    expect(tester.getSize(find.byType(UiLayer)).width, 10);
  });
}
