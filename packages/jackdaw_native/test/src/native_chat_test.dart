import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/jackdaw_native.dart';
import 'package:jackdaw_native/src/native/native_features.dart';
import 'package:test/test.dart';

import 'model_fixture.dart';

Future<String> _text(Stream<ModelEvent> events) async => [
  await for (final e in events)
    if (e case TextDelta(:final text)) text,
].join();

void main() {
  group(
    'chat on the worker',
    skip: testModelPath == null ? noModel : false,
    () {
      late NativeModel model;

      setUpAll(() async => model = await NativeModel.load(testModelPath!));
      tearDownAll(() => model.dispose());

      test('the source build renders chats natively', () {
        expect(nativeChat, isTrue);
      });

      test('a chat gives the same answer as its rendered prompt', () async {
        const messages = [
          ('system', 'You are terse.'),
          ('user', 'Name a bird.'),
        ];
        const options = NativeGenerateOptions(maxTokens: 8);
        final session = NativeSession(model);
        addTearDown(session.dispose);
        final rendered = await _text(
          session.generate(model.applyTemplate(messages), options),
        );
        expect(await _text(session.generateChat(messages, options)), rendered);
      });

      test('generation can use fewer threads', () async {
        final session = NativeSession(
          model,
          options: const NativeSessionOptions(threads: 4, generateThreads: 2),
        );
        addTearDown(session.dispose);
        final text = await _text(
          session.generateChat(const [
            ('user', 'Count from one to five.'),
          ], const NativeGenerateOptions(maxTokens: 8)),
        );
        expect(text, isNotEmpty);
      });
    },
  );
}
