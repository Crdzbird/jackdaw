import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_mcp/jackdaw_mcp.dart';
import 'package:test/test.dart';

import 'support/fake_session.dart';

final class _Caller implements LanguageModel {
  @override
  String get id => 'test/caller';

  @override
  Stream<ModelEvent> generate(ModelRequest request) =>
      Stream.fromIterable(switch (request.messages.last.role) {
        Role.user => const [
          ToolCallEvent(
            ToolCallPart(id: 'c1', name: 'web_search_fetch', arguments: {}),
          ),
          FinishEvent(reason: FinishReason.toolCalls),
        ],
        _ => const [TextDelta('done'), FinishEvent(reason: FinishReason.stop)],
      });
}

void main() {
  test('MCP tools wait for approval and their output is screened', () async {
    final session = FakeSession([
      {'name': 'fetch'},
    ]);
    final agent = Agent(
      model: _Caller(),
      tools: await mcpTools(session),
      store: InMemorySessionStore(),
    );
    final first = await agent.send('s', Message.user('look it up')).toList();
    expect(
      (first.last as AgentFinished).reason,
      AgentStopReason.awaitingApproval,
    );
    expect(session.calls, isEmpty);
    final second = await agent.decide('s', {
      'c1': const ApprovalDecision.approve(),
    }).toList();
    final done = second.last as AgentFinished;
    expect(done.reason, AgentStopReason.completed);
    expect(session.calls, hasLength(1));
    final result =
        done.messages.firstWhere((m) => m.role == Role.tool).parts.single
            as ToolResultPart;
    final screened = result.output! as Map;
    expect(screened['warning'], contains('instruction override'));
    expect((screened['output'] as Map)['note'], mcpOutputNote);
    await session.close();
    expect(session.closed, isTrue);
  });
}
