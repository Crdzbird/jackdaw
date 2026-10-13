import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/jackdaw_native.dart';
import 'package:test/test.dart';

import 'model_fixture.dart';

void main() {
  group('with a model', skip: testModelPath == null ? noModel : false, () {
    late NativeModel model;

    setUpAll(() async => model = await NativeModel.load(testModelPath!));
    tearDownAll(() => model.dispose());

    test('empty prompts are rejected by the core', () {
      final session = NativeSession(model);
      addTearDown(session.dispose);
      expect(
        session.generate('', const NativeGenerateOptions()).toList(),
        throwsA(isA<NativeException>()),
      );
      expect(model.countTokens(''), 0);
    });

    test('disposing during a generation releases waiting callers', () async {
      final session = NativeSession(model);
      final subscription = session
          .generate(
            model.applyTemplate([('user', 'Tell a long story.')]),
            const NativeGenerateOptions(temperature: 0.7),
          )
          .listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 300));
      session.dispose();
      await session.idle;
      await subscription.cancel();
    });

    test('local models expose stats and idle', () async {
      final local = await LocalModel.open(testModelPath!);
      addTearDown(local.close);
      await local
          .generate(
            ModelRequest(
              messages: [Message.user('Hi')],
              options: const GenerationOptions(maxOutputTokens: 2),
            ),
          )
          .drain<void>();
      await local.idle;
      expect(local.stats.generatedTokens, lessThanOrEqualTo(2));
      expect(local.stats.totalMs, greaterThan(0));
    });
  });
}
