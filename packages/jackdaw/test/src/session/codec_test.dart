import 'dart:convert';

import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

SessionRecord roundTrip(SessionRecord record) => recordFromJson(
  jsonDecode(jsonEncode(recordToJson(record))) as Map<String, Object?>,
);

void main() {
  test('messages with every part survive a JSON round trip', () {
    const message = Message(
      role: Role.assistant,
      parts: [
        TextPart('hi'),
        ReasoningPart(provider: 'p', text: 't', data: {'s': 1}),
        ToolCallPart(
          id: 'c',
          name: 'n',
          arguments: {'a': 1},
          providerData: {'x': 'y'},
        ),
      ],
    );
    final back = roundTrip(const MessageRecord(message)) as MessageRecord;
    expect(
      jsonEncode(messageToJson(back.message)),
      jsonEncode(messageToJson(message)),
    );
  });

  test('every record type survives a JSON round trip', () {
    const result = ToolResultPart(
      callId: 'c',
      name: 'n',
      output: {'v': 2},
      isError: true,
    );
    final finished =
        roundTrip(const ToolResultRecord(result)) as ToolResultRecord;
    expect(
      [finished.result.callId, finished.result.isError, finished.result.output],
      [
        'c',
        true,
        {'v': 2},
      ],
    );
    expect(
      (roundTrip(const ToolStartedRecord('c')) as ToolStartedRecord).callId,
      'c',
    );
    final asked = roundTrip(
      const ApprovalRequestedRecord('c', 'why'),
    ) as ApprovalRequestedRecord;
    expect([asked.callId, asked.reason], ['c', 'why']);
    final decided = roundTrip(
      const ApprovalDecidedRecord('c', granted: false, note: 'no'),
    ) as ApprovalDecidedRecord;
    expect([decided.callId, decided.granted, decided.note], ['c', false, 'no']);
  });

  test('the in-memory store keeps journals per session', () async {
    final store = InMemorySessionStore();
    await store.append('a', const ToolStartedRecord('1'));
    expect(await store.load('a'), hasLength(1));
    expect(await store.load('b'), isEmpty);
  });
}
