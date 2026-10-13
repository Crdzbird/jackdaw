import 'dart:async';

import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/policy/tool_decision.dart';
import 'package:jackdaw/src/tool/tool.dart';

/// Decides whether a tool call may run, must be refused, or needs a
/// person's approval.
///
/// Policies run inside the agent, next to the tools, and are never decided
/// by data that arrives from a client or from the model.
abstract interface class ToolPolicy {
  /// Decides about [call] to the registered [tool].
  FutureOr<ToolDecision> decide(ToolCallPart call, Tool<Object?> tool);
}
