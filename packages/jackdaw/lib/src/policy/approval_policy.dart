import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/policy/tool_decision.dart';
import 'package:jackdaw/src/policy/tool_policy.dart';
import 'package:jackdaw/src/tool/tool.dart';

/// The default policy: registered tools run, except those declared with
/// `requiresApproval`, which wait for a person.
///
/// Tools that are not registered never run, so registration is the
/// allow-list.
final class ApprovalPolicy implements ToolPolicy {
  /// Creates the default policy.
  const factory() = ApprovalPolicy._;

  const new _();

  @override
  ToolDecision decide(ToolCallPart call, Tool<Object?> tool) =>
      tool.requiresApproval
      ? ToolDecision.ask('${tool.name} requires approval')
      : const ToolDecision.allow();
}
