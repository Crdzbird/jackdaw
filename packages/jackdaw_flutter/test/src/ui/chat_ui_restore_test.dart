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
  testWidgets('a restored chat shows its surfaces again', (tester) async {
    final first = UiSurfaceController(basicCatalog);
    final model = ScriptedModel([
      show(signupForm, 'c1'),
      textTurn(['Here.']),
    ]);
    final store = InMemorySessionStore();
    final chat = ChatController(
      agent: Agent(
        model: model,
        tools: [first.tool(format: UiFormat.messages)],
        store: store,
      ),
      sessionId: 's',
      ui: first,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChatView(controller: chat)),
      ),
    );
    await settle(tester, chat.send('Show it'));
    final history = chat.messages.value;
    await chat.dispose();
    final ui = UiSurfaceController(basicCatalog);
    final restored = ChatController(
      agent: Agent(
        model: model,
        tools: [ui.tool(format: UiFormat.messages)],
        store: store,
      ),
      sessionId: 's',
      history: history,
      ui: ui,
    );
    expect(ui.surfaces.surfaces.keys, ['signup']);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChatView(controller: restored)),
      ),
    );
    expect(find.text('Email'), findsOneWidget);
    await restored.dispose();
  });
}
