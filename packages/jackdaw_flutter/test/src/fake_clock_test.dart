import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_test/jackdaw_test.dart';

void main() {
  test('an agent run completes under a fake clock, as in widget tests', () {
    var done = false;
    FakeAsync().run((async) {
      final agent = Agent(
        model: ScriptedModel([
          textTurn(['caw']),
        ]),
      );
      unawaited(agent.complete([Message.user('hi')]).then((_) => done = true));
      async.flushMicrotasks();
    });
    expect(done, isTrue);
  });
}
