import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_bench/src/app/demo_colors.dart';
import 'package:jackdaw_bench/src/app/genui_renderer.dart';
import 'package:jackdaw_bench/src/app/jackdaw_renderer.dart';
import 'package:jackdaw_bench/src/app/studio_renderer.dart';
import 'package:jackdaw_test/jackdaw_test.dart';

ScriptedModel _model() => ScriptedModel([
  textTurn([
    jsonEncode({
      'surfaceId': 'red',
      'root': {
        'component': 'Panel',
        'color': 'red',
        'child': {'component': 'Text', 'text': 'On red'},
      },
    }),
  ]),
]);

void main() {
  for (final (name, make) in <(String, StudioRenderer Function())>[
    ('jackdaw_flutter', () => JackdawRenderer((_) {})),
    ('genui', () => GenuiRenderer((_) {})),
  ]) {
    testWidgets('$name draws the Panel', (tester) async {
      final renderer = make();
      final problems = await renderer.generate(_model(), [
        Message.user('Red'),
      ], (_) {});
      expect(problems.where((p) => !p.warning), isEmpty);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: renderer.view())),
      );
      await tester.pumpAndSettle();
      expect(find.text('On red'), findsOneWidget);
      final boxes = tester.widgetList<ColoredBox>(find.byType(ColoredBox));
      expect(boxes.map((b) => b.color), contains(demoColor('red')));
      renderer.dispose();
    });
  }
}
