import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/policy/tool_decision.dart';
import 'package:jackdaw/src/policy/tool_policy.dart';
import 'package:jackdaw/src/tool/tool.dart';

/// A default-deny policy built from explicit rules.
///
/// Tools named in [allow] run, tools named in [ask] wait for approval and
/// all other tools are denied. A [guard] may refuse individual calls, for
/// example to block arguments that point outside an allowed folder.
final class RulePolicy implements ToolPolicy {
  /// Creates a policy from rules.
  const factory({
    Set<String> allow,
    Set<String> ask,
    String? Function(ToolCallPart call)? guard,
  }) = RulePolicy._;

  const new _({this.allow = const {}, this.ask = const {}, this.guard});

  /// Tools that run without approval.
  final Set<String> allow;

  /// Tools that wait for approval.
  final Set<String> ask;

  /// Returns a reason to deny [ToolCallPart]s it rejects, or `null`.
  final String? Function(ToolCallPart call)? guard;

  @override
  ToolDecision decide(ToolCallPart call, Tool<Object?> tool) {
    if (guard?.call(call) case final reason?) return ToolDecision.deny(reason);
    if (ask.contains(tool.name)) {
      return ToolDecision.ask('${tool.name} requires approval');
    }
    if (allow.contains(tool.name)) return const ToolDecision.allow();
    return ToolDecision.deny('${tool.name} is not allowed by policy');
  }
}
