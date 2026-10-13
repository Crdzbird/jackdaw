import 'dart:async';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_test/jackdaw_test.dart';
import 'package:test/test.dart';

import 'support/counting_tool.dart';
import 'support/reactive_model.dart';

ToolCallPart ask(String id) =>
    ToolCallPart(id: id, name: 'expert', arguments: const {'task': 'look up'});

void main() {
  test('a sub-agent answer becomes the tool result', () async {
    final expert = Agent(
      model: ScriptedModel([
        textTurn(['found it']),
      ]),
    );
    final lead = Agent(
      model: ReactiveModel([ask('e1')]),
      tools: [delegateTo(expert, name: 'expert', description: 'Researches')],
    );
    final done = await lead.complete([Message.user('help')]);
    final result = done.messages[2].parts.single as ToolResultPart;
    expect(result.output, 'found it');
    expect(result.isError, isFalse);
  });

  test('delegation deeper than the limit fails the call', () async {
    final expert = Agent(
      model: ScriptedModel([
        textTurn(['unused']),
      ]),
    );
    final tool = delegateTo(
      expert,
      name: 'expert',
      description: 'd',
      maxDepth: 2,
    );
    final result = await runZoned(
      () => tool.invoke(ask('deep')),
      zoneValues: {#jackdaw.delegationDepth: 2},
    );
    expect(result.isError, isTrue);
    expect(result.output, {'error': 'Bad state: delegation deeper than 2'});
  });

  test('a sub-agent waiting for approval fails the call', () async {
    final expert = Agent(
      model: ReactiveModel([
        const ToolCallPart(id: 'p', name: 'pay', arguments: {}),
      ]),
      tools: [
        countingTool('pay', [0], requiresApproval: true),
      ],
    );
    final tool = delegateTo(expert, name: 'expert', description: 'd');
    final result = await tool.invoke(ask('e'));
    expect(result.isError, isTrue);
    expect(result.output, {
      'error': 'Bad state: expert stopped: awaitingApproval',
    });
  });
}
