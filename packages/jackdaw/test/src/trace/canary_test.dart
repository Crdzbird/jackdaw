import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import 'support/leaky_model.dart';
import 'support/leaky_tools.dart';

const _canary = 'canary-7f3a9c2e51d0';
const _unregistered = 'sk-ant-unregisteredKey0123456789';

String _dump(List<RecordedSpan> spans) =>
    [for (final s in spans) '${s.name} ${s.attributes} ${s.error}'].join('\n');

void main() {
  test('secrets never reach a trace, even with content capture on', () async {
    final recorder = RecordingTracer();
    final agent = Agent(
      model: LeakyModel(_canary),
      tools: leakyTools(_canary),
      instructions: 'Use $_canary and $_unregistered carefully.',
      tracer: RedactingTracer(recorder, Redactor([const Secret(_canary)])),
      traceContent: true,
    );
    final done = await agent.complete([Message.user('key $_canary')]);
    expect(done.reason, AgentStopReason.completed);
    final dump = _dump(recorder.spans);
    expect(recorder.spans, hasLength(5));
    expect(dump, contains('[redacted]'));
    expect(dump, isNot(contains(_canary)));
    expect(dump, isNot(contains(_unregistered)));
    expect(dump, isNot(contains('AKIAABCDEFGHIJKLMNOP')));
    expect(dump, isNot(contains('abcdefghijklmnopqrstuvwxyz')));
  });

  test('without redaction the canary does reach the trace', () async {
    final recorder = RecordingTracer();
    await Agent(
      model: LeakyModel(_canary),
      tools: leakyTools(_canary),
      tracer: recorder,
      traceContent: true,
    ).complete([Message.user('key')]);
    expect(_dump(recorder.spans), contains(_canary));
  });

  test('credential shapes are redacted even from a plain tracer', () async {
    final recorder = RecordingTracer();
    await Agent(
      model: LeakyModel(_unregistered),
      tools: leakyTools(_unregistered),
      tracer: recorder,
      traceContent: true,
    ).complete([Message.user('key')]);
    expect(_dump(recorder.spans), isNot(contains(_unregistered)));
  });

  test('a failing model call is traced without its secret', () async {
    final recorder = RecordingTracer();
    final agent = Agent(
      model: LeakyModel(_canary, fail: true),
      tracer: RedactingTracer(recorder, Redactor([const Secret(_canary)])),
    );
    await expectLater(
      agent.run([Message.user('hi')]).drain<void>(),
      throwsStateError,
    );
    expect(recorder.spans.map((s) => s.name), [
      'chat test/leaky',
      'invoke_agent',
    ]);
    expect(recorder.spans.every((s) => s.error != null), isTrue);
    expect(_dump(recorder.spans), isNot(contains(_canary)));
  });

  test('the redactor walks maps and lists and leaves other values', () {
    final redactor = Redactor([const Secret(_canary), const Secret('')]);
    expect(
      redactor.redact({
        'a': [_canary, 3, null],
        'b': {'c': 'x $_canary y'},
      }),
      {
        'a': ['[redacted]', 3, null],
        'b': {'c': 'x [redacted] y'},
      },
    );
    expect(redactor.redact('ghp_${'a' * 36}'), '[redacted]');
    expect(redactor.redact('AIza${'b' * 35}'), '[redacted]');
    expect(redactor.redact(true), isTrue);
  });
}
