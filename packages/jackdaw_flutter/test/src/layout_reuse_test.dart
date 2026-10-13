import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';

import 'support/manual_model.dart';

RenderParagraph _paragraph(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    );

void main() {
  testWidgets('a finished answer keeps the layout of its streamed text', (
    tester,
  ) async {
    final model = ManualModel();
    final chat = ChatController(
      agent: Agent(model: model, store: InMemorySessionStore()),
      sessionId: 's',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChatView(controller: chat)),
      ),
    );
    final turn = chat.send('go');
    await tester.pump();
    model.events.add(const TextDelta('First paragraph.\n\nSecond'));
    await tester.pump();
    await tester.pump();
    final streamed = _paragraph(tester, 'First paragraph.');
    expect(find.bySemanticsLabel('Assistant is answering'), findsOneWidget);
    model.events
      ..add(const TextDelta(' paragraph.'))
      ..add(const FinishEvent(reason: FinishReason.stop));
    await model.events.close();
    await turn;
    await tester.pump();
    final finished = _paragraph(tester, 'First paragraph.');
    expect(identical(streamed, finished), isTrue);
    expect(find.text('Second paragraph.'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Assistant said')), findsOneWidget);
  });

  testWidgets('earlier bubbles keep their layout when a turn starts', (
    tester,
  ) async {
    final model = ManualModel();
    final history = [
      Message.user('Old question'),
      const Message(role: Role.assistant, parts: [TextPart('Old answer')]),
    ];
    final store = InMemorySessionStore();
    for (final message in history) {
      await store.append('s', MessageRecord(message));
    }
    final chat = ChatController(
      agent: Agent(model: model, store: store),
      sessionId: 's',
      history: history,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChatView(controller: chat)),
      ),
    );
    final before = _paragraph(tester, 'Old answer');
    final turn = chat.send('New question');
    await tester.pump();
    model.events.add(const TextDelta('New'));
    await tester.pump();
    await tester.pump();
    expect(identical(_paragraph(tester, 'Old answer'), before), isTrue);
    model.events.add(const FinishEvent(reason: FinishReason.stop));
    await model.events.close();
    await turn;
    await tester.pump();
    expect(identical(_paragraph(tester, 'Old answer'), before), isTrue);
  });
}
