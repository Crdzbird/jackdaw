import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import 'support/counting_tool.dart';
import 'support/crashing_store.dart';
import 'support/process_killed.dart';
import 'support/reactive_model.dart';

const _calls = [
  ToolCallPart(id: 'charge-1', name: 'charge', arguments: {}),
  ToolCallPart(id: 'lookup-1', name: 'lookup', arguments: {}),
];

void main() {
  test(
    'a session killed at any write resumes without repeating effects',
    () async {
      for (var crashAt = 1; crashAt <= 9; crashAt++) {
        final journal = InMemorySessionStore();
        final charges = [0];
        final lookups = [0];
        Agent agent(SessionStore store) => Agent(
          model: ReactiveModel(_calls),
          tools: [
            countingTool('charge', charges),
            countingTool('lookup', lookups, idempotent: true),
          ],
          store: store,
        );
        final crashing = agent(CrashingStore(journal, crashAt: crashAt));
        Object? crash;
        try {
          await crashing.send('s', Message.user('pay')).drain<void>();
        } on ProcessKilled catch (error) {
          crash = error;
        }
        final events = await agent(journal).resume('s').toList();
        final done = events.last as AgentFinished;
        final reason = 'crash at write $crashAt ($crash)';
        expect(done.reason, AgentStopReason.completed, reason: reason);
        expect(charges[0], lessThanOrEqualTo(1), reason: reason);
        final tool = done.messages.where((m) => m.role == Role.tool).toList();
        expect(tool.length, lessThanOrEqualTo(1), reason: reason);
        if (tool.isNotEmpty) {
          expect(tool.single.parts, hasLength(2), reason: reason);
        }
      }
    },
  );

  test('tools receive their call id as an idempotency key', () async {
    final runs = [0];
    final agent = Agent(
      model: ReactiveModel(const [_lookup]),
      tools: [countingTool('lookup', runs)],
    );
    final done = await agent.complete([Message.user('go')]);
    final result = done.messages[2].parts.single as ToolResultPart;
    expect((result.output! as Map)['key'], 'lookup-1');
    expect(ToolContext.callId, isNull);
  });
}

const _lookup = ToolCallPart(id: 'lookup-1', name: 'lookup', arguments: {});
