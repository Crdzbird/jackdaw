import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/jackdaw_native.dart';
import 'package:test/test.dart';

import 'model_fixture.dart';

void main() {
  group('with a model', skip: testModelPath == null ? noModel : false, () {
    late LocalModel model;

    setUpAll(() async {
      model = await LocalModel.open(
        testModelPath!,
        options: const LocalModelOptions(
          session: NativeSessionOptions(contextTokens: 2048),
        ),
      );
    });

    tearDownAll(() => model.close());

    test('streams text and reports usage', () async {
      final events = await model
          .generate(
            ModelRequest(
              messages: [Message.user('Name one bird.')],
              options: const GenerationOptions(maxOutputTokens: 12),
            ),
          )
          .toList();
      final finish = events.last as FinishEvent;
      expect(events.whereType<TextDelta>(), isNotEmpty);
      expect(finish.usage.inputTokens, greaterThan(0));
      expect(finish.usage.outputTokens, lessThanOrEqualTo(12));
      expect(model.id, startsWith('local/'));
    });

    test('structured output always matches the schema', () async {
      const schema = ObjectSchema(
        properties: {
          'bird': Schema.string(),
          'canFly': Schema.boolean(),
          'wingspanCm': Schema.integer(),
        },
        required: ['bird', 'canFly', 'wingspanCm'],
      );
      final value = await generateJson(model, [
        Message.user('Describe a jackdaw.'),
      ], schema);
      expect(schema.validate(value), isEmpty);
    });

    test('counts tokens with the model vocabulary', () {
      expect(model.countTokens('Hello world'), inInclusiveRange(1, 4));
    });
  });
}
