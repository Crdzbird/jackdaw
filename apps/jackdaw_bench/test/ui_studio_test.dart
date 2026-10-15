import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw_bench/src/app/ui_studio.dart';
import 'package:jackdaw_test/jackdaw_test.dart';

void main() {
  testWidgets('the screen the model builds is drawn', (tester) async {
    final model = ScriptedModel([
      textTurn([
        jsonEncode({
          'surfaceId': 'signup',
          'root': {
            'component': 'Column',
            'children': [
              {'component': 'Text', 'text': 'Join the club'},
              {'component': 'TextField', 'label': 'Name', 'value': '/name'},
              {
                'component': 'Button',
                'child': {'component': 'Text', 'text': 'Sign up'},
                'action': {
                  'event': {'name': 'submit'},
                },
              },
            ],
          },
        }),
      ]),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: UiStudio(model: model)),
      ),
    );
    await tester.tap(find.text('Build'));
    await tester.pumpAndSettle();
    expect(find.text('Join the club'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
  });
}
