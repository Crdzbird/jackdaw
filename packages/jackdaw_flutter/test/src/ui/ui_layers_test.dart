import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/show_surface.dart';

void main() {
  testWidgets('a write repaints only the component that reads it', (
    tester,
  ) async {
    final controller = await showSurface(
      tester,
      [
        c('root', 'Column', {
          'children': ['fixed', 'bound', 'line'],
        }),
        c('fixed', 'Text', {'text': 'Fixed'}),
        c('bound', 'Text', {
          'text': {'@path': '/name'},
        }),
        c('line', 'Divider'),
      ],
      data: {'name': 'Bound'},
    );
    final painted = <String>[];
    debugProfilePaintsEnabled = true;
    debugOnProfilePaint = (o) => painted.add(switch (o) {
      RenderParagraph(:final text) => text.toPlainText(),
      RenderDecoratedBox() => 'line',
      _ => '',
    });
    controller.write('s', '/name', 'A much longer bound text');
    await tester.pump();
    debugProfilePaintsEnabled = false;
    debugOnProfilePaint = null;
    expect(painted, contains('A much longer bound text'));
    expect(painted, isNot(contains('Fixed')));
    expect(painted, isNot(contains('line')));
  });
}
