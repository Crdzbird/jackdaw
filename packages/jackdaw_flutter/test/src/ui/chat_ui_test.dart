import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';
import 'package:jackdaw_test/jackdaw_test.dart';

import '../support/idle.dart';
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
  testWidgets('the agent shows a form in the chat and hears the press', (
    tester,
  ) async {
    final ui = UiSurfaceController(basicCatalog);
    final model = ScriptedModel([
      show(signupForm, 'c1'),
      textTurn(['Fill it in.']),
      textTurn(['Thanks, signed up.']),
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
    await settle(tester, chat.send('Sign me up'));
    expect(find.text('Fill it in.'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Assistant showed')), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'ana@x.io');
    await tester.pump();
    await tester.tap(find.text('Sign up'));
    expect(chat.status.value, ChatStatus.responding);
    await settle(tester, idle(chat));
    await tester.pump();
    expect(find.text('Thanks, signed up.'), findsOneWidget);
    final sent = chat.messages.value.where((m) => uiActionCaption(m) != null);
    expect(sent.single.text, contains('"email":"ana@x.io"'));
    expect(find.textContaining('UI action'), findsNothing);
    await chat.dispose();
  });
}
