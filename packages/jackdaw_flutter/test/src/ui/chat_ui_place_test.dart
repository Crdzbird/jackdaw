import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';
import 'package:jackdaw_test/jackdaw_test.dart';

import '../support/settle.dart';
import 'ui_form.dart';

List<ModelEvent> show(Map<String, Object?> message, String id) => toolCallTurn([
  ToolCallPart(
    id: id,
    name: 'render_ui',
    arguments: {
      'messages': [message],
    },
  ),
]);

void main() {
  testWidgets('a surface shows at the last place it was shown', (tester) async {
    final ui = UiSurfaceController(basicCatalog);
    final model = ScriptedModel([
      show(signupForm, 'c1'),
      textTurn(['First.']),
      show(signupForm, 'c2'),
      textTurn(['Again.']),
    ]);
    final chat = ChatController(
      agent: Agent(
        model: model,
        tools: [ui.tool(format: UiFormat.messages)],
        store: InMemorySessionStore(),
      ),
      sessionId: 's',
      ui: ui,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChatView(controller: chat)),
      ),
    );
    await settle(tester, chat.send('one'));
    await settle(tester, chat.send('two'));
    expect(find.bySemanticsLabel(RegExp('^Assistant showed')), findsOneWidget);
    ui.applyAll([
      {
        'version': 'v1.0',
        'deleteSurface': {'surfaceId': 'signup'},
      },
    ]);
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('^Assistant showed')), findsOneWidget);
    await chat.dispose();
  });
}
