import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import 'support/leaky_model.dart';
import 'support/leaky_tools.dart';

void main() {
  test('a run produces nested spans with usage and no content', () async {
    final recorder = RecordingTracer();
    final agent = Agent(
      model: LeakyModel('plain'),
      tools: leakyTools('plain'),
      tracer: recorder,
    );
    await agent.complete([Message.user('go')]);
    final spans = {for (final s in recorder.spans) s.name: s};
    expect(recorder.spans.map((s) => s.name), [
      'chat test/leaky',
      'execute_tool lookup',
      'execute_tool explode',
      'chat test/leaky',
      'invoke_agent',
    ]);
    final run = spans['invoke_agent']!;
    expect(run.attributes['gen_ai.conversation.id'], 'run');
    expect(run.attributes['jackdaw.stop_reason'], 'completed');
    expect(run.attributes['gen_ai.usage.input_tokens'], 30);
    expect(run.attributes['gen_ai.usage.output_tokens'], 9);
    expect(run.error, isNull);
    expect(spans['execute_tool lookup']!.error, isNull);
    expect(spans['execute_tool explode']!.error, isNotNull);
    expect(spans['chat test/leaky']!.attributes, {
      'gen_ai.operation.name': 'chat',
      'gen_ai.request.model': 'test/leaky',
      'gen_ai.response.finish_reasons': ['stop'],
      'gen_ai.usage.input_tokens': 20,
      'gen_ai.usage.output_tokens': 5,
    });
    expect(run.duration, greaterThanOrEqualTo(Duration.zero));
    expect(
      recorder.spans.expand((s) => s.attributes.values),
      isNot(contains('plain')),
    );
  });

  test('cancelling a traced model call ends its span once', () async {
    final recorder = RecordingTracer();
    final model = TracedModel(_Endless(), recorder, content: true);
    final first = await model
        .generate(ModelRequest(messages: [Message.user('hi')]))
        .first;
    expect(first, isA<TextDelta>());
    expect(recorder.spans, hasLength(1));
    expect(recorder.spans.single.attributes['gen_ai.input.messages'], [
      {'role': 'user', 'content': 'hi'},
    ]);
    expect(model.id, 'test/endless');
  });

  test('the no-op tracer accepts everything', () {
    const NoopTracer().startSpan('x')
      ..setAttribute('k', 1)
      ..end(error: 'e');
  });
}

final class _Endless implements LanguageModel {
  @override
  String get id => 'test/endless';

  @override
  Stream<ModelEvent> generate(ModelRequest request) => Stream.periodic(
    const Duration(milliseconds: 1),
    (_) => const TextDelta('a'),
  );
}
