import 'dart:async';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/jackdaw_native.dart';
import 'package:test/test.dart';

import 'model_fixture.dart';

void main() {
  group('with a model', skip: testModelPath == null ? noModel : false, () {
    late NativeModel model;
    late NativeSession session;

    setUpAll(() async {
      model = await NativeModel.load(testModelPath!);
      session = NativeSession(
        model,
        options: const NativeSessionOptions(contextTokens: 2048),
      );
    });

    tearDownAll(() {
      session.dispose();
      model.dispose();
    });

    String prompt(String user) => model.applyTemplate([('user', user)]);

    test('cancelling stops native work and the next request runs', () async {
      final story = session.generate(
        prompt('Write a very long story about a jackdaw.'),
        const NativeGenerateOptions(temperature: 0.8, seed: 3),
      );
      final first = await story.first;
      final stopwatch = Stopwatch()..start();
      await session.idle;
      stopwatch.stop();
      expect(first, isA<TextDelta>());
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      final next = await session
          .generate(
            prompt('Say ok.'),
            const NativeGenerateOptions(maxTokens: 4),
          )
          .toList();
      expect(next.last, isA<FinishEvent>());
    });

    test('back to back requests run in order', () async {
      const options = NativeGenerateOptions(maxTokens: 3);
      final results = await Future.wait([
        session.generate(prompt('One.'), options).toList(),
        session.generate(prompt('Two.'), options).toList(),
      ]);
      expect(
        results.map((events) => events.last),
        everyElement(isA<FinishEvent>()),
      );
    });

    test('a second turn reuses the cached prefix', () async {
      const options = NativeGenerateOptions(maxTokens: 4);
      final base = prompt('Name a bird that lives in cities.');
      await session.generate(base, options).drain<void>();
      await session.generate('${base}Pigeons.', options).drain<void>();
      expect(session.stats.reusedTokens, greaterThan(10));
    });

    test('bad grammars fail the stream with a NativeException', () {
      expect(
        session
            .generate(
              prompt('hi'),
              const NativeGenerateOptions(grammar: 'root ::= ('),
            )
            .toList(),
        throwsA(
          isA<NativeException>().having(
            (e) => e.message,
            'message',
            'grammar does not parse',
          ),
        ),
      );
    });

    test('loading a missing file throws', () {
      expect(
        NativeModel.load('/nonexistent.gguf'),
        throwsA(isA<NativeException>()),
      );
    });
  });
}
