import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jackdaw_bench/src/app/demo_app.dart';
import 'package:jackdaw_bench/src/app/model_path.dart';

Future<void> _say(WidgetTester tester, String text) async {
  await tester.tap(find.byType(TextField));
  await tester.pump();
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.byTooltip('Send'));
  await tester.pump();
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 600 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the demo chats with the on-device model', (tester) async {
    final folder = '${File(modelPath).parent.path}/sessions';
    final journal = File('$folder/demo.jsonl');
    final notes = File('$folder/notes.json');
    for (final file in [journal, notes]) {
      if (file.existsSync()) file.deleteSync();
    }
    await tester.pumpWidget(const DemoApp());
    await _until(tester, find.text('Ask the model'));
    await _say(tester, 'Name one bird.');
    await _until(tester, find.byTooltip('Send'));
    await _until(tester, find.bySemanticsLabel(RegExp('^Assistant said')));
    expect(journal.existsSync(), isTrue);
    await _say(tester, 'Save a note: buy bread.');
    await _until(tester, find.text('Run save_note?'));
    expect(notes.existsSync(), isFalse);
    await tester.tap(find.text('Approve'));
    for (var i = 0; i < 600 && !notes.existsSync(); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(notes.readAsStringSync(), contains('bread'));
    final answers = find.bySemanticsLabel(RegExp('^Assistant said'));
    for (var i = 0; i < 600 && answers.evaluate().length < 2; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(answers, findsNWidgets(2));
    await tester.tap(find.text('Playground'));
    await tester.pumpAndSettle();
    expect(find.text('Generate'), findsOneWidget);
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New chat'));
    final answer = find.bySemanticsLabel(RegExp('^Assistant said'));
    for (var i = 0; i < 50 && answer.evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(answer, findsNothing);
    await _until(tester, find.text('Ask the model'));
    expect(journal.existsSync(), isFalse);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
