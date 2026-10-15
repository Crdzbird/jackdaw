import 'dart:io';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/jackdaw_native.dart';
import 'package:test/test.dart';

import 'model_fixture.dart';

ModelRequest _ask(String question) => ModelRequest(
  messages: [
    Message.system('You are a terse assistant. ' * 20),
    Message.user(question),
  ],
  options: const GenerationOptions(maxOutputTokens: 4),
);

void main() {
  group('saved state', skip: testModelPath == null ? noModel : false, () {
    late Directory folder;

    setUp(() => folder = Directory.systemTemp.createTempSync('jackdaw_state'));
    tearDown(() => folder.deleteSync(recursive: true));

    test('a loaded state skips the prompt it saved', () async {
      final file = File('${folder.path}/state.bin');
      final first = await LocalModel.open(testModelPath!);
      await first.generate(_ask('Name a bird.')).drain<void>();
      await first.saveState(file);
      first.close();
      expect(file.lengthSync(), greaterThan(0));

      final second = await LocalModel.open(testModelPath!);
      addTearDown(second.close);
      expect(await second.loadState(file), greaterThan(100));
      await second.generate(_ask('Name a fish.')).drain<void>();
      expect(second.stats.reusedTokens, greaterThan(100));
    });

    test('a missing or foreign state restores nothing', () async {
      final model = await LocalModel.open(testModelPath!);
      addTearDown(model.close);
      expect(await model.loadState(File('${folder.path}/none.bin')), 0);
      final junk = File('${folder.path}/junk.bin')..writeAsStringSync('junk');
      expect(await model.loadState(junk), 0);
      await model.generate(_ask('Name a tree.')).drain<void>();
      expect(model.stats.reusedTokens, 0);
    });
  });
}
