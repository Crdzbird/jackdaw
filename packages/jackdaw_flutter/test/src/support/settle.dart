import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Waits for [future] inside a widget test whose work spans both the fake
/// clock and the real event loop, such as cancelling an agent run.
///
/// Each round lets the real loop run once and then pumps a frame, until
/// the future completes.
Future<T> settle<T>(WidgetTester tester, Future<T> future) async {
  late T value;
  Object? failure;
  StackTrace? trace;
  var done = false;
  unawaited(
    future.then(
      (result) {
        value = result;
        done = true;
      },
      onError: (Object error, StackTrace stack) {
        failure = error;
        trace = stack;
        done = true;
      },
    ),
  );
  for (var round = 0; round < 100 && !done; round++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  if (!done) throw TimeoutException('future did not settle');
  if (failure case final error?) Error.throwWithStackTrace(error, trace!);
  return value;
}
