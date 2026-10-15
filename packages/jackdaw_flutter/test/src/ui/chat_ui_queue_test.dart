import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';
import 'package:jackdaw_test/jackdaw_test.dart';

import '../support/settle.dart';

UiAction press(String name) => UiAction(
  name: name,
  surfaceId: 's',
  sourceComponentId: 'b',
  timestamp: DateTime.utc(2026),
);

void main() {
  testWidgets('an action during a turn waits for it to end', (tester) async {
    final ui = UiSurfaceController(basicCatalog);
    final chat = ChatController(
      agent: Agent(
        model: ScriptedModel([
          textTurn(['First answer.']),
          textTurn(['Heard the press.']),
        ]),
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
    final first = chat.send('Hello');
    ui.onAction!(press('go'));
    await settle(tester, first);
    for (var i = 0; i < 20 && chat.messages.value.length < 4; i++) {
      await settle(tester, Future<void>.value());
    }
    final texts = [for (final m in chat.messages.value) m.text];
    expect(texts.first, 'Hello');
    expect(texts, contains('Heard the press.'));
    expect(uiActionCaption(chat.messages.value[2]), '');
    await chat.dispose();
  });

  test('an app that handles actions itself keeps its handler', () {
    final seen = <UiAction>[];
    final ui = UiSurfaceController(basicCatalog, onAction: seen.add);
    ChatController(
      agent: Agent(
        model: ScriptedModel(const []),
        store: InMemorySessionStore(),
      ),
      sessionId: 's',
      ui: ui,
    );
    ui.onAction!(press('mine'));
    expect(seen.single.name, 'mine');
  });
}
