import 'dart:async';
import 'dart:convert';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_test/src/contract/contract_case.dart';
import 'package:jackdaw_test/src/contract/contract_requests.dart';
import 'package:matcher/expect.dart';
import 'package:test_api/scaffolding.dart';

/// Declares the tests every [LanguageModel] must pass, for the model that
/// [model] returns.
///
/// Before each case [prepare] runs, so a fake can script what the case
/// needs; a real model needs none. The same suite runs against the native
/// and the web models, which is how they are held to the same behaviour.
void languageModelContract(
  LanguageModel Function() model, {
  Future<void> Function(ContractCase contractCase)? prepare,
}) {
  Future<List<ModelEvent>> run(ContractCase c, ModelRequest request) async {
    await prepare?.call(c);
    return await model().generate(request).toList();
  }

  String text(List<ModelEvent> events) =>
      events.whereType<TextDelta>().map((e) => e.text).join();

  test('a reply ends with exactly one finish event', () async {
    final events = await run(ContractCase.text, contractRequest('Say hello.'));
    expect(events.whereType<FinishEvent>(), hasLength(1));
    expect(events.last, isA<FinishEvent>());
    expect(text(events), isNotEmpty);
  });

  test('the token limit stops the reply', () async {
    final events = await run(
      ContractCase.limit,
      contractRequest('Count from one to one hundred in words.', limit: 3),
    );
    final finish = events.last as FinishEvent;
    expect(finish.reason, FinishReason.length);
    expect(finish.usage.outputTokens ?? 0, lessThanOrEqualTo(3));
  });

  test('a response schema yields JSON that matches it', () async {
    final request = contractRequest('Is water wet? Answer in JSON.');
    final events = await run(
      ContractCase.schema,
      ModelRequest(
        messages: request.messages,
        options: request.options,
        responseSchema: contractSchema,
      ),
    );
    expect(contractSchema.validate(jsonDecode(text(events))), isEmpty);
  });

  test('tool calls carry unique ids and valid arguments', () async {
    final request = contractRequest('Call the ping tool with the text hello.');
    final events = await run(
      ContractCase.toolCall,
      ModelRequest(
        messages: request.messages,
        options: request.options,
        tools: const [contractTool],
      ),
    );
    final calls = [for (final e in events.whereType<ToolCallEvent>()) e.call];
    expect(calls, isNotEmpty);
    expect({for (final c in calls) c.id}, hasLength(calls.length));
    for (final call in calls) {
      expect(call.name, contractTool.name);
      expect(contractTool.input.validate(call.arguments), isEmpty);
    }
    expect((events.last as FinishEvent).reason, FinishReason.toolCalls);
  });

  test('cancelling stops the reply and the next request works', () async {
    await prepare?.call(ContractCase.cancel);
    final first = Completer<void>();
    final subscription = model()
        .generate(contractRequest('Write a long story.', limit: 256))
        .listen((_) => first.isCompleted ? null : first.complete());
    await first.future;
    await subscription.cancel();
    final events = await run(ContractCase.text, contractRequest('Say hi.'));
    expect(events.last, isA<FinishEvent>());
  });

  test('generate never throws synchronously', () {
    expect(
      () => model().generate(const ModelRequest(messages: [])),
      returnsNormally,
    );
  });
}
