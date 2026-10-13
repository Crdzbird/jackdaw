@TestOn('browser')
library;

import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import 'web_harness.dart';

const _tool = ToolSpec(
  name: 'get_weather',
  description: 'Weather for a city',
  input: ObjectSchema(properties: {'city': Schema.string()}),
);

void main() {
  test('tools use the shared prompt, grammar and decoder', () async {
    final model = await openFake();
    script([
      chunk({'content': '<tool_call>\n{"name": "get_weather", '}),
      chunk({'content': '"arguments": {"city": "Lima"}}\n</tool_call>'}),
      chunk(const {}, finish: 'stop'),
    ]);
    final events = await model
        .generate(
          ModelRequest(
            messages: [Message.user('Weather?')],
            tools: const [_tool],
          ),
        )
        .toList();
    final call = events.whereType<ToolCallEvent>().single.call;
    expect(
      [call.name, call.arguments],
      [
        'get_weather',
        {'city': 'Lima'},
      ],
    );
    expect(call.id, startsWith('call_'));
    expect((events.last as FinishEvent).reason, FinishReason.toolCalls);
    final options = state('options')! as Map;
    expect(options.containsKey('tools'), isFalse);
    expect(options['grammar'], contains('get_weather'));
    final messages = options['messages']! as List;
    expect((messages.first as Map)['role'], 'system');
    expect((messages.first as Map)['content'], contains('<tools>'));
  });
}
