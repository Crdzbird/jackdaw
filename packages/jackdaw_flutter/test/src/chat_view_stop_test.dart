import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';

import 'support/endless_model.dart';
import 'support/settle.dart';

Future<ChatController> _show(
  WidgetTester tester,
  LanguageModel model, {
  List<Tool<Object?>> tools = const [],
}) async {
  final chat = ChatController(
    agent: Agent(model: model, tools: tools, store: InMemorySessionStore()),
    sessionId: 's',
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: ChatView(controller: chat)),
    ),
  );
  return chat;
}

void main() {
  testWidgets('the stop button ends a streaming answer', (tester) async {
    final endless = EndlessModel();
    final chat = await _show(tester, endless);
    final turn = chat.send('go');
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();
    expect(find.textContaining('tick'), findsOneWidget);
    await tester.tap(find.byTooltip('Stop'));
    await settle(tester, turn);
    await tester.pump();
    expect(find.textContaining('tick'), findsNothing);
    expect(find.byTooltip('Send'), findsOneWidget);
    expect(endless.cancelled, isTrue);
  });
}
