import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import '../agent/support/counting_tool.dart';

const _key = 'canary-3b8e0d71aa';

final class _Leaker implements LanguageModel {
  @override
  String get id => 'test/leaker';

  @override
  Stream<ModelEvent> generate(ModelRequest request) {
    if (request.messages.last.role == Role.user) {
      return Stream.fromIterable(const [
        ToolCallEvent(
          ToolCallPart(
            id: 'c1',
            name: 'post',
            arguments: {
              'body': ['report', 'key=$_key'],
            },
          ),
        ),
        ToolCallEvent(
          ToolCallPart(id: 'c2', name: 'post', arguments: {'body': 'hello'}),
        ),
        FinishEvent(reason: FinishReason.toolCalls),
      ]);
    }
    return Stream.fromIterable(const [
      TextDelta('ok'),
      FinishEvent(reason: FinishReason.stop),
    ]);
  }
}

void main() {
  test('calls carrying a secret are blocked before they run', () async {
    final runs = [0];
    final agent = Agent(
      model: _Leaker(),
      tools: [countingTool('post', runs)],
      policy: EgressPolicy(
        const ApprovalPolicy(),
        Redactor([const Secret(_key)]),
      ),
    );
    final done = await agent.complete([Message.user('send the report')]);
    expect(runs[0], 1);
    final results = done.messages[2].parts.cast<ToolResultPart>();
    expect(results.first.isError, isTrue);
    expect('${results.first.output}', contains('contain a secret'));
    expect('${results.first.output}', isNot(contains(_key)));
    expect(results.last.isError, isFalse);
  });

  test('credential shapes are found in nested values', () {
    final redactor = Redactor(const []);
    expect(
      redactor.finds({
        'a': ['Bearer abcdefghijklmnopqrstu'],
      }),
      isTrue,
    );
    expect(
      redactor.finds({
        'a': ['plain', 1, null],
      }),
      isFalse,
    );
    expect(redactor.finds(42), isFalse);
  });
}
