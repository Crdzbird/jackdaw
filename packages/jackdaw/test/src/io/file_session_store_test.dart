@TestOn('vm')
library;

import 'dart:io';

import 'package:jackdaw/io.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late FileSessionStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('jackdaw_sessions');
    store = FileSessionStore(Directory('${dir.path}/journals'));
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('appends survive reopening the store', () async {
    await store.append('s-1', MessageRecord(Message.user('hi')));
    await store.append('s-1', const ToolStartedRecord('c'));
    final reopened = FileSessionStore(store.directory);
    final records = await reopened.load('s-1');
    expect((records.first as MessageRecord).message.text, 'hi');
    expect(records.last, isA<ToolStartedRecord>());
    expect(await reopened.load('unknown'), isEmpty);
  });

  test('a torn last line is dropped, earlier damage is reported', () async {
    await store.append('s', const ToolStartedRecord('a'));
    final file = File('${store.directory.path}/s.jsonl')
      ..writeAsStringSync('{"type":"tool', mode: FileMode.append);
    expect(await store.load('s'), hasLength(1));
    file.writeAsStringSync('{"broken"\n{"type":"toolStarted","callId":"b"}\n');
    await expectLater(store.load('s'), throwsFormatException);
  });

  test('session ids cannot escape the folder', () {
    expect(() => store.load('../etc/passwd'), throwsArgumentError);
    expect(
      () => store.append('a/b', const ToolStartedRecord('c')),
      throwsArgumentError,
    );
  });

  test('agents resume from a file journal', () async {
    final agent = Agent(model: _Echo(), store: store);
    await agent.send('chat', Message.user('ping')).drain<void>();
    final again = Agent(
      model: _Echo(),
      store: FileSessionStore(store.directory),
    );
    final done =
        (await again.send('chat', Message.user('ping 2')).toList()).last
            as AgentFinished;
    expect(done.messages.map((m) => m.text), [
      'ping',
      'echo',
      'ping 2',
      'echo',
    ]);
  });
}

final class _Echo implements LanguageModel {
  @override
  String get id => 'test/echo';

  @override
  Stream<ModelEvent> generate(ModelRequest request) => Stream.fromIterable(
    const [TextDelta('echo'), FinishEvent(reason: FinishReason.stop)],
  );
}
