import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test(
    'collects thinking, redacted thinking and fragmented tool input',
    () async {
      final events = await run([
        start(0, {'type': 'thinking', 'thinking': '', 'signature': ''}),
        delta(0, {'type': 'thinking_delta', 'thinking': 'Plan.'}),
        delta(0, {'type': 'signature_delta', 'signature': 'sig'}),
        stop(0),
        start(1, {'type': 'redacted_thinking', 'data': 'opaque'}),
        stop(1),
        start(2, {
          'type': 'tool_use',
          'id': 'toolu_1',
          'name': 'weather',
          'input': <String, Object?>{},
        }),
        delta(2, {'type': 'input_json_delta', 'partial_json': ''}),
        delta(2, {'type': 'input_json_delta', 'partial_json': '{"city":'}),
        delta(2, {'type': 'input_json_delta', 'partial_json': ' "Lima"}'}),
        stop(2),
        start(3, {
          'type': 'tool_use',
          'id': 'toolu_2',
          'name': 'now',
          'input': <String, Object?>{},
        }),
        stop(3),
        start(4, {
          'type': 'tool_use',
          'id': 'toolu_3',
          'name': 'bad',
          'input': <String, Object?>{},
        }),
        delta(4, {'type': 'input_json_delta', 'partial_json': '{oops'}),
        stop(4),
        start(5, {'type': 'server_tool_use', 'id': 's', 'name': 'web_search'}),
        stop(5),
        messageDelta('tool_use', 40),
      ]);
      final reasoning = events
          .whereType<ReasoningEvent>()
          .map((e) => e.part)
          .toList();
      final calls = events
          .whereType<ToolCallEvent>()
          .map((e) => e.call)
          .toList();
      expect(reasoning.first.text, 'Plan.');
      expect(reasoning.first.data, {
        'type': 'thinking',
        'thinking': 'Plan.',
        'signature': 'sig',
      });
      expect(reasoning.last.data, {
        'type': 'redacted_thinking',
        'data': 'opaque',
      });
      expect(reasoning.last.provider, 'anthropic');
      expect(calls.map((c) => c.arguments), [
        {'city': 'Lima'},
        <String, Object?>{},
        '{oops',
      ]);
      expect((events.last as FinishEvent).reason, FinishReason.toolCalls);
    },
  );
}
