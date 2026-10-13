@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

import '../../tool/offline_check.dart';
import 'model_fixture.dart';

final class _NoNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw StateError('the offline agent loop tried to use the network');
}

void main() {
  test(
    'claim C9: tools, retrieval and structured output run without network',
    skip: testModelPath == null ? noModel : false,
    () async {
      final problem = await HttpOverrides.runZoned(
        () => offlineCheck(testModelPath!),
        createHttpClient: _NoNetwork().createHttpClient,
      );
      expect(problem, isNull);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
