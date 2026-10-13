import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';
import 'package:jackdaw_test/jackdaw_test.dart';

import 'support/approval_tool.dart';
import 'support/broken_model.dart';
import 'support/endless_model.dart';
import 'support/settle.dart';

ChatController _chat(
  LanguageModel model, {
  List<Tool<Object?>> tools = const [],
}) => ChatController(
  agent: Agent(model: model, tools: tools, store: InMemorySessionStore()),
  sessionId: 's',
);

void main() {
  testWidgets('a turn streams text and ends with the transcript', (
    tester,
  ) async {
    final chat = _chat(
      ScriptedModel([
        textTurn(['Jack', 'daws']),
      ]),
    );
    final statuses = <ChatStatus>[];
    chat.status.addListener(() => statuses.add(chat.status.value));
    await chat.send('hi');
    expect(chat.messages.value.map((m) => m.text), ['hi', 'Jackdaws']);
    expect(statuses, [ChatStatus.responding, ChatStatus.idle]);
    expect(chat.streaming.value, isEmpty);
    await chat.dispose();
  });

  testWidgets('approvals pause the turn until decided', (tester) async {
    final runs = [0];
    final chat = _chat(
      ScriptedModel([
        toolCallTurn([
          const ToolCallPart(
            id: 'c1',
            name: 'send_email',
            arguments: {'to': 'a'},
          ),
        ]),
        textTurn(['sent']),
      ]),
      tools: [approvalTool(runs)],
    );
    await chat.send('email a');
    expect(chat.status.value, ChatStatus.awaitingApproval);
    expect(chat.approvals.value.single.call.id, 'c1');
    expect(runs[0], 0);
    await chat.decide('c1', const ApprovalDecision.approve());
    expect(chat.approvals.value, isEmpty);
    expect(runs[0], 1);
    expect(chat.messages.value.last.text, 'sent');
    expect(chat.status.value, ChatStatus.idle);
  });

  testWidgets('failures are reported', (tester) async {
    final broken = _chat(BrokenModel());
    await broken.send('hi');
    expect(broken.status.value, ChatStatus.failed);
    expect('${broken.state.error}', contains('model offline'));
  });

  testWidgets('stop cancels the model', (tester) async {
    final endless = EndlessModel();
    final chat = _chat(endless);
    final turn = chat.send('go');
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();
    expect(chat.streaming.value, startsWith('tick'));
    expect(() => chat.send('again'), throwsStateError);
    final stopping = chat.stop();
    expect(chat.status.value, ChatStatus.idle);
    await settle(tester, stopping);
    await settle(tester, turn);
    expect(chat.status.value, ChatStatus.idle);
    expect(chat.streaming.value, isEmpty);
    expect(endless.cancelled, isTrue);
    expect(
      () => ChatController(
        agent: Agent(model: endless),
        sessionId: 'x',
      ),
      throwsArgumentError,
    );
  });
}
