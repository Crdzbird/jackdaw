import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/jackdaw_native.dart';
import 'package:test/test.dart';

import 'model_fixture.dart';

const _component = Schema.union(
  discriminator: 'component',
  variants: {
    'Text': ObjectSchema(
      properties: {
        'text': Schema.string(),
        'variant': Schema.string(enumValues: ['h1', 'body', 'caption']),
      },
      required: ['text', 'variant'],
    ),
    'Button': ObjectSchema(
      properties: {'label': Schema.string(), 'action': Schema.string()},
      required: ['label', 'action'],
    ),
    'Slider': ObjectSchema(
      properties: {'min': Schema.number(), 'max': Schema.number()},
      required: ['min', 'max'],
    ),
  },
);

void main() {
  group('with a model', skip: testModelPath == null ? noModel : false, () {
    late LocalModel model;

    setUpAll(() async => model = await LocalModel.open(testModelPath!));
    tearDownAll(() => model.close());

    test('union output is always one valid variant', () async {
      for (final prompt in [
        'A title that says Welcome.',
        'A button to save the form.',
        'A control to pick a volume from 0 to 11.',
      ]) {
        final value = await generateJson(
          model,
          [Message.user('Describe one UI component for: $prompt')],
          _component,
          options: const GenerationOptions(maxOutputTokens: 96),
        );
        expect(_component.validate(value), isEmpty, reason: '$value');
        printOnFailure('$prompt -> $value');
      }
    });
  });
}
