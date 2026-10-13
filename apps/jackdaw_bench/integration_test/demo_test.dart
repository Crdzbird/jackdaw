import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jackdaw_bench/src/app/demo_app.dart';
import 'package:jackdaw_bench/src/app/model_path.dart';

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 600 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the demo chats with the on-device model', (tester) async {
    final journal = File('${File(modelPath).parent.path}/sessions/demo.jsonl');
    if (journal.existsSync()) journal.deleteSync();
    await tester.pumpWidget(const DemoApp());
    await _until(tester, find.text('Ask the model'));
    await tester.enterText(find.byType(TextField), 'Name one bird.');
    await tester.tap(find.byTooltip('Send'));
    await _until(tester, find.byTooltip('Send'));
    await _until(tester, find.bySemanticsLabel('Assistant said'));
    expect(journal.existsSync(), isTrue);
    await tester.tap(find.text('Playground'));
    await tester.pumpAndSettle();
    expect(find.text('Generate'), findsOneWidget);
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New chat'));
    for (var i = 0; i < 50; i++) {
      if (find.bySemanticsLabel('Assistant said').evaluate().isEmpty) break;
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.bySemanticsLabel('Assistant said'), findsNothing);
    await _until(tester, find.text('Ask the model'));
    expect(journal.existsSync(), isFalse);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
