import 'dart:async';

import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/policy/tool_decision.dart';
import 'package:jackdaw/src/policy/tool_policy.dart';
import 'package:jackdaw/src/tool/tool.dart';
import 'package:jackdaw/src/trace/redactor.dart';

/// Refuses tool calls whose arguments carry a secret, then defers to
/// the inner policy.
///
/// A model that read a key in a document or a tool result could otherwise
/// pass it to a tool that sends data out, such as a web request. Secrets
/// are those given to the `Redactor` plus common credential shapes. The refusal
/// never repeats the secret.
final class EgressPolicy implements ToolPolicy {
  /// Guards [inner] with [redactor].
  const factory(ToolPolicy inner, Redactor redactor) = EgressPolicy._;

  const new _(this._inner, this._redactor);

  final ToolPolicy _inner;
  final Redactor _redactor;

  @override
  FutureOr<ToolDecision> decide(ToolCallPart call, Tool<Object?> tool) {
    if (_redactor.finds(call.arguments)) {
      return const ToolDecision.deny(
        'the arguments contain a secret, so the call was blocked',
      );
    }
    return _inner.decide(call, tool);
  }
}
