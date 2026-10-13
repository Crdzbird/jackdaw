@TestOn('vm')
library;

import 'dart:io';

import 'package:jackdaw/io.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_cli/jackdaw_cli.dart';
import 'package:test/test.dart';

Future<String> _run(List<String> args, {int code = 0}) async {
  final out = StringBuffer();
  expect(await runCli(args, out), code, reason: '$out');
  return '$out';
}

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('jackdaw_cli'));
  tearDown(() => dir.delete(recursive: true));

  test('inspect prints a timeline and what the session waits for', () async {
    final store = FileSessionStore(dir);
    const call = ToolCallPart(id: 'c1', name: 'send', arguments: {'to': 'kim'});
    for (final record in <SessionRecord>[
      MessageRecord(Message.user('email kim')),
      const MessageRecord(Message(role: Role.assistant, parts: [call])),
      const ApprovalRequestedRecord('c1', 'send requires approval'),
    ]) {
      await store.append('chat', record);
    }
    final waiting = await _run(['inspect', '${dir.path}/chat.jsonl']);
    expect(waiting, contains('   1  user:             email kim'));
    expect(waiting, contains('tool call:        c1 send {"to":"kim"}'));
    expect(waiting, contains('approval asked    c1'));
    expect(waiting, endsWith('waiting for approval of c1\n'));
    for (final record in <SessionRecord>[
      const ApprovalDecidedRecord('c1', granted: false, note: 'no'),
      const ToolStartedRecord('c1'),
      const ToolResultRecord(
        ToolResultPart(
          callId: 'c1',
          name: 'send',
          output: {'error': 'x'},
          isError: true,
        ),
      ),
      const MessageRecord(
        Message(role: Role.assistant, parts: [TextPart('Not sent.')]),
      ),
    ]) {
      await store.append('chat', record);
    }
    final done = await _run(['inspect', '${dir.path}/chat.jsonl']);
    expect(done, contains('rejected          c1: no'));
    expect(done, contains('tool started      c1'));
    expect(done, contains('tool failed       c1 {"error":"x"}'));
    expect(done, endsWith('7 records, 1 tool calls; answered\n'));
  });

  test('inspect reports open calls, empty journals and bad paths', () async {
    final store = FileSessionStore(dir);
    await store.append(
      'open',
      const MessageRecord(
        Message(
          role: Role.assistant,
          parts: [ToolCallPart(id: 'c9', name: 'look', arguments: {})],
        ),
      ),
    );
    expect(
      await _run(['inspect', '${dir.path}/open.jsonl']),
      contains('tool calls not finished: c9'),
    );
    await store.append(
      'asked',
      MessageRecord(Message.user('${'long ' * 40}end')),
    );
    final asked = await _run(['inspect', '${dir.path}/asked.jsonl']);
    expect(asked, contains('...'));
    expect(asked, contains('waiting for the model'));
    File('${dir.path}/empty.jsonl').writeAsStringSync('');
    expect(
      await _run(['inspect', '${dir.path}/empty.jsonl']),
      contains('empty'),
    );
    await _run(['inspect', '${dir.path}/missing.jsonl'], code: 66);
    await _run(['inspect', 'notes.txt'], code: 64);
  });
}
