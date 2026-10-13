import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';
import 'package:jackdaw_test/jackdaw_test.dart';

void main() {
  testWidgets('sending works the moment the chat turns idle', (tester) async {
    final chat = ChatController(
      agent: Agent(
        model: ScriptedModel([
          textTurn(['first']),
          textTurn(['second']),
        ]),
        store: InMemorySessionStore(),
      ),
      sessionId: 's',
    );
    Future<void>? next;
    chat.status.addListener(() {
      if (chat.status.value == ChatStatus.idle && next == null) {
        next = chat.send('again');
      }
    });
    await chat.send('hi');
    await next;
    expect(chat.messages.value.map((m) => m.text), [
      'hi',
      'first',
      'again',
      'second',
    ]);
  });
}
