import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/jackdaw_native.dart';
import 'package:test/test.dart';

import 'model_fixture.dart';

void main() {
  group('with a model', skip: testModelPath == null ? noModel : false, () {
    late LocalModel model;

    setUpAll(() async => model = await LocalModel.open(testModelPath!));
    tearDownAll(() => model.close());

    test('UI replies are valid A2UI messages for the catalog', () async {
      final schemas = UiSchemas(basicCatalog);
      final value = await generateJson(
        model,
        [Message.user('A login form with email and password fields.')],
        schemas.reply,
        options: const GenerationOptions(maxOutputTokens: 800),
      );
      expect(schemas.messages.validate(value), isEmpty);
      printOnFailure('$value');
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
