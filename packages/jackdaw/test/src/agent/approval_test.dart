import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import 'support/counting_tool.dart';
import 'support/reactive_model.dart';

const _pay = ToolCallPart(id: 'pay-1', name: 'pay', arguments: {'eur': 5});

void main() {
  late List<int> runs;
  late Agent agent;

  setUp(() {
    runs = [0];
    agent = Agent(
      model: ReactiveModel(const [_pay], answer: 'paid'),
      tools: [countingTool('pay', runs, requiresApproval: true)],
      store: InMemorySessionStore(),
    );
  });

  test('a call needing approval stops the run without running', () async {
    final events = await agent.send('s', Message.user('pay')).toList();
    final asked = events.whereType<AgentApprovalRequested>().single;
    expect(asked.call, same(_pay));
    expect(asked.reason, 'pay requires approval');
    expect(
      (events.last as AgentFinished).reason,
      AgentStopReason.awaitingApproval,
    );
    expect(runs[0], 0);
    final again = await agent.resume('s').toList();
    expect(
      (again.last as AgentFinished).reason,
      AgentStopReason.awaitingApproval,
    );
  });

  test('only pending calls can be decided', () async {
    await agent.send('s', Message.user('pay')).drain<void>();
    await expectLater(
      agent.decide('s', {
        'made-up': const ApprovalDecision.approve(),
      }).drain<void>(),
      throwsArgumentError,
    );
    expect(runs[0], 0);
  });

  test('approval runs the exact call once and continues', () async {
    await agent.send('s', Message.user('pay')).drain<void>();
    final events = await agent.decide('s', {
      'pay-1': const ApprovalDecision.approve(),
    }).toList();
    final done = events.last as AgentFinished;
    expect(runs[0], 1);
    expect(done.reason, AgentStopReason.completed);
    expect(done.text, 'paid');
    await expectLater(
      agent.decide('s', {
        'pay-1': const ApprovalDecision.approve(),
      }).drain<void>(),
      throwsArgumentError,
    );
  });

  test('rejection is reported to the model and nothing runs', () async {
    await agent.send('s', Message.user('pay')).drain<void>();
    final events = await agent.decide('s', {
      'pay-1': const ApprovalDecision.reject('too costly'),
    }).toList();
    final result = events.whereType<AgentToolResult>().single.result;
    expect(runs[0], 0);
    expect(result.output, {'error': 'rejected: too costly'});
  });

  test('policies deny unlisted tools and unknown tools never run', () async {
    final denied = Agent(
      model: ReactiveModel(const [
        _pay,
        ToolCallPart(id: 'x', name: 'ghost', arguments: {}),
      ]),
      tools: [countingTool('pay', runs)],
      policy: const RulePolicy(),
    );
    final done = await denied.complete([Message.user('pay')]);
    final results = done.messages[2].parts.cast<ToolResultPart>();
    expect(runs[0], 0);
    expect(results.map((r) => r.output), [
      {'error': 'pay is not allowed by policy'},
      {'error': 'unknown tool ghost'},
    ]);
  });

  test('sessions need a store', () {
    final stateless = Agent(model: ReactiveModel(const []));
    expect(stateless.resume('s').drain<void>(), throwsStateError);
  });
}
