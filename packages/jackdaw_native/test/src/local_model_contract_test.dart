import 'package:jackdaw_native/jackdaw_native.dart';
import 'package:jackdaw_test/jackdaw_test.dart';
import 'package:test/test.dart';

import 'model_fixture.dart';

/// Claim C8: the native model passes the same contract as the web model.
void main() {
  group(
    'LocalModel contract',
    skip: testModelPath == null ? noModel : false,
    () {
      late LocalModel model;

      setUpAll(() async => model = await LocalModel.open(testModelPath!));
      tearDownAll(() => model.close());

      languageModelContract(() => model);
    },
  );
}
