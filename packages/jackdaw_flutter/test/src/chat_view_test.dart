import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';
import 'package:jackdaw_test/jackdaw_test.dart';

import 'support/approval_tool.dart';

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
  testWidgets('typing sends and the answer appears', (tester) async {
    await _show(
      tester,
      ScriptedModel([
        textTurn(['Corvids ', 'cache food.']),
      ]),
    );
    await tester.enterText(find.byType(TextField), 'What do jackdaws do?');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    await tester.pump();
    expect(find.text('What do jackdaws do?'), findsOneWidget);
    expect(find.text('Corvids cache food.'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^You said')), findsOneWidget);
  });

  testWidgets('approval cards run or refuse the call', (tester) async {
    final runs = [0];
    await _show(
      tester,
      ScriptedModel([
        toolCallTurn([
          const ToolCallPart(
            id: 'c1',
            name: 'send_email',
            arguments: {'to': 'kim'},
          ),
        ]),
        textTurn(['Sent.']),
      ]),
      tools: [approvalTool(runs)],
    );
    await tester.enterText(find.byType(TextField), 'email kim');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    expect(find.text('Run send_email?'), findsOneWidget);
    expect(find.textContaining('"to": "kim"'), findsOneWidget);
    await tester.tap(find.text('Approve'));
    await tester.pump();
    await tester.pump();
    expect(runs[0], 1);
    expect(find.text('Sent.'), findsOneWidget);
    expect(find.text('Run send_email?'), findsNothing);
  });

  testWidgets('rejecting and failures are shown', (tester) async {
    final runs = [0];
    final chat = await _show(
      tester,
      ScriptedModel([
        toolCallTurn([
          const ToolCallPart(id: 'c1', name: 'send_email', arguments: {}),
        ]),
        textTurn(['Not sent.']),
      ]),
      tools: [approvalTool(runs)],
    );
    await chat.send('email');
    await tester.pump();
    await tester.tap(find.text('Reject'));
    await tester.pump();
    await tester.pump();
    expect(runs[0], 0);
    expect(find.text('Not sent.'), findsOneWidget);
    await chat.send('again');
    await tester.pump();
    expect(find.textContaining('Something went wrong'), findsOneWidget);
  });
}
