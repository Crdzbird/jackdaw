import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

final class _Flaky implements LanguageModel {
  int calls = 0;

  @override
  String get id => 'test/flaky';

  @override
  Stream<ModelEvent> generate(ModelRequest request) {
    calls++;
    if (calls == 1) {
      return Stream.fromIterable(const <ModelEvent>[TextDelta('par')])
          .followedBy(Stream.error(StateError('connection reset')));
    }
    return Stream.fromIterable(const [
      TextDelta('answer'),
      FinishEvent(reason: FinishReason.stop),
    ]);
  }
}

extension<T> on Stream<T> {
  Stream<T> followedBy(Stream<T> next) async* {
    yield* this;
    yield* next;
  }
}

void main() {
  test('a failed model call ends the run and journals nothing', () async {
    final model = _Flaky();
    final store = InMemorySessionStore();
    final agent = Agent(model: model, store: store);
    final events = <AgentEvent>[];
    Object? failure;
    await agent
        .send('s', Message.user('hi'))
        .handleError((Object error) => failure = error)
        .forEach(events.add);
    expect('$failure', contains('connection reset'));
    expect(events.whereType<AgentFinished>(), isEmpty);
    expect(await store.load('s'), hasLength(1));
    final resumed = await agent.resume('s').last as AgentFinished;
    expect(resumed.reason, AgentStopReason.completed);
    expect(resumed.messages.map((m) => m.text), ['hi', 'answer']);
    expect(model.calls, 2);
  });
}
