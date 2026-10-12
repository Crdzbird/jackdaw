@TestOn('browser')
library;

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_web/jackdaw_web.dart';
import 'package:test/test.dart';

import 'web_harness.dart';

void main() {
  late WebLocalModel model;

  setUp(() async => model = await openFake());

  test('streams tool calls with numeric indexes', () async {
    script([
      chunk({
        'tool_calls': [
          {
            'index': 0,
            'id': 'c1',
            'function': {'name': 'w', 'arguments': '{"city":"Lima"}'},
          },
        ],
      }, finish: 'tool_calls'),
    ]);
    final events = await model
        .generate(const ModelRequest(messages: []))
        .toList();
    final call = events.whereType<ToolCallEvent>().single.call;
    expect(
      [call.id, call.name, call.arguments],
      [
        'c1',
        'w',
        {'city': 'Lima'},
      ],
    );
  });

  test('engine failures surface as ProviderException', () async {
    script(const [], error: 'out of memory');
    await expectLater(
      model.generate(const ModelRequest(messages: [])).toList(),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.message,
          'm',
          contains('out of memory'),
        ),
      ),
    );
    await model.close();
    expect(state('exited'), isTrue);
  });
}
