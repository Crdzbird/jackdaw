import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

Tool<Object?> tool(String name, {bool approval = false}) => Tool<Object?>(
  name: name,
  description: name,
  input: const ObjectSchema(properties: {}, additionalProperties: true),
  decode: (json) => json,
  run: (input) => 'ok',
  requiresApproval: approval,
);

ToolCallPart call(String name, [Object? args = const {}]) =>
    ToolCallPart(id: '1', name: name, arguments: args);

void main() {
  test('the default policy asks only for tools that require approval', () {
    const policy = ApprovalPolicy();
    expect(policy.decide(call('a'), tool('a')), isA<ToolAllowed>());
    final asked = policy.decide(call('b'), tool('b', approval: true));
    expect((asked as ToolNeedsApproval).reason, 'b requires approval');
  });

  test('rule policies deny anything not listed and honour guards', () {
    final policy = RulePolicy(
      allow: const {'read'},
      ask: const {'write'},
      guard: (c) =>
          c.arguments == 'secret' ? 'secret paths are off limits' : null,
    );
    expect(policy.decide(call('read'), tool('read')), isA<ToolAllowed>());
    expect(
      policy.decide(call('write'), tool('write')),
      isA<ToolNeedsApproval>(),
    );
    expect(
      (policy.decide(call('rm'), tool('rm')) as ToolDenied).reason,
      'rm is not allowed by policy',
    );
    expect(
      (policy.decide(
        call('read', 'secret'),
        tool('read'),
      ) as ToolDenied).reason,
      'secret paths are off limits',
    );
  });

  test('decision factories and approval decisions', () {
    expect(const ToolDecision.allow(), isA<ToolAllowed>());
    expect((const ToolDecision.deny('no') as ToolDenied).reason, 'no');
    expect((const ToolDecision.ask('why') as ToolNeedsApproval).reason, 'why');
    expect(const ApprovalDecision.approve().granted, isTrue);
    expect(const ApprovalDecision.reject().note, 'rejected by the user');
    expect(const ApprovalDecision.reject('too costly').granted, isFalse);
  });
}
